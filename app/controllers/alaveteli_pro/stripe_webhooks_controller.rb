# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController
  class MissingTypeStripeWebhookError < StandardError; end
  class UnknownPlanStripeWebhookError < StandardError; end
  class DuplicateStripeWebhookError < StandardError; end

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

  rescue_from DuplicateStripeWebhookError do |exception|
    # accept it so it doesn't get resent but don't process it
    # (and don't generate an exception email for it)
    render json: { message: 'Looks like a duplicate' }, status: 200
  end

  rescue_from UnknownPlanStripeWebhookError do |exception|
    # accept it so it doesn't get resent but don't process it
    # (and don't generate an exception email for it)
    render json: { message: 'Does not appear to be one of our plans' },
           status: 200
  end

  before_action :read_event_notification, :check_for_event_type,
                :check_for_duplicate_event, :filter_hooks

  def receive
    case @stripe_event.type
    when 'customer.subscription.deleted'
      customer_subscription_deleted
      log_webhook(@stripe_event)
    when 'invoice.payment_succeeded'
      invoice_payment_succeeded
      log_webhook(@stripe_event)
    when 'invoice.payment_failed'
      invoice_payment_failed
      log_webhook(@stripe_event)
    else
      store_unhandled_webhook
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: { message: 'OK' }, status: 200
  end

  private

  def log_webhook(event)
    ProcessedWebhook.create(event_id: event.id)
  end

  def customer_subscription_deleted
    account = pro_account_from_stripe_event(@stripe_event)
    account.user.remove_role(:pro) if account
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

  def invoice_payment_failed
    account = pro_account_from_stripe_event(@stripe_event)
    if account
      AlaveteliPro::SubscriptionMailer.payment_failed(account.user).deliver_now
    end
  end

  def store_unhandled_webhook
    Webhook.create(params: @stripe_event.to_h)
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

  def pro_account_from_stripe_event(event)
    customer_id = event.data.object.customer
    ProAccount.find_by(stripe_customer_id: customer_id)
  end

  def check_for_event_type
    unless @stripe_event.respond_to?(:type)
      msg = "undefined method `type' for #{ @stripe_event.inspect }"
      raise MissingTypeStripeWebhookError.new(msg)
    end
  end

  def check_for_duplicate_event
    if ProcessedWebhook.find_by(event_id: @stripe_event.id)
      raise DuplicateStripeWebhookError
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
