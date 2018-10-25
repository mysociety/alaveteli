# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController
  class UnhandledStripeWebhookError < StandardError ; end
  class MissingTypeStripeWebhookError < StandardError ; end
  class UnknownPlanStripeWebhookError < StandardError ; end

  rescue_from JSON::ParserError, MissingTypeStripeWebhookError do |exception|
    # Invalid payload, reject the webhook
    notify_exception(exception)
    render json: { error: exception.message }, status: 400
  end

  rescue_from Stripe::SignatureVerificationError do |exception|
    # Invalid signature, reject the webhook
    notify_exception(exception)
    render json: { error: exception.message }, status: 401
  end

  rescue_from UnknownPlanStripeWebhookError do |exception|
    # accept it so it doesn't get resent but don't process it
    # (and don't generate an exception email for it)
    render json: { message: 'Does not appear to be one of our plans' },
           status: 200
  end

  rescue_from UnhandledStripeWebhookError do |exception|
    # accept it so it doesn't get resent but notify us that we haven't handled
    # it yet.
    notify_exception(exception)
    render json: { message: 'OK' }, status: 200
  end

  before_action :read_event_notification, :check_for_event_type, :filter_hooks

  def receive
    case @stripe_event.type
    when 'customer.subscription.deleted'
      customer_subscription_deleted
    when 'invoice.payment_succeeded'
      invoice_payment_succeeded
    else
      raise UnhandledStripeWebhookError.new(@stripe_event.type)
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: { message: 'OK' }, status: 200
  end

  private

  def customer_subscription_deleted
    customer_id = @stripe_event.data.object.customer
    if account = ProAccount.find_by(stripe_customer_id: customer_id)
      account.user.remove_role(:pro)
    end
  end

  def invoice_payment_succeeded
    charge_id = @stripe_event.data.object.charge

    if charge_id
      charge = Stripe::Charge.retrieve(charge_id)

      subscription_id = @stripe_event.data.object.subscription
      subscription = Stripe::Subscription.retrieve(subscription_id)
      plan_name = subscription.plan.name

      charge.description =
        "#{ AlaveteliConfiguration.pro_site_name }: #{ plan_name }"

      charge.save
    end
  end

  def read_event_notification
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = AlaveteliConfiguration.stripe_webhook_secret
    @stripe_event = nil

    @stripe_event = Stripe::Webhook.construct_event(
      payload, sig_header, endpoint_secret
    )
  end

  def check_for_event_type
    unless @stripe_event.respond_to?(:type)
      msg = "undefined method `type' for #{ @stripe_event.inspect }"
      raise MissingTypeStripeWebhookError.new(msg)
    end
  end

  def notify_exception(error)
    return unless send_exception_notifications?
    ExceptionNotifier.notify_exception(error, env: request.env)
  end

  # ignore any that don't match our plan namespace
  def filter_hooks
    plans = []
    case @stripe_event.data.object.object
    when 'subscription'
      plans = plan_ids(@stripe_event.data.object.items)
    when 'invoice'
      plans = plan_ids(@stripe_event.data.object.lines)
    end

    # ignore any plans that don't start with our namespace
    plans.delete_if { |plan| !plan_matches_namespace?(plan) }

    raise UnknownPlanStripeWebhookError if plans.empty?
  end

  def plan_matches_namespace?(plan_id)
    (AlaveteliConfiguration.stripe_namespace == '' ||
     plan_id =~ /^#{AlaveteliConfiguration.stripe_namespace}/)
  end

  def plan_ids(items)
    items.map { |item| item.plan.id if item.plan }.compact.uniq
  end
end
