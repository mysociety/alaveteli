# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController
  class MissingTypeStripeWebhookError < StandardError; end
  class UnknownPlanStripeWebhookError < StandardError; end

  skip_before_action :html_response

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

  rescue_from UnknownPlanStripeWebhookError do |_exception|
    # accept it so it doesn't get resent but don't process it
    # (and don't generate an exception email for it)
    render json: { message: 'Does not appear to be one of our plans' },
           status: 200
  end

  before_action :read_event_notification, :check_for_event_type, :filter_hooks

  def receive
    case @stripe_event.type
    when 'customer.subscription.deleted'
      customer_subscription_deleted
    when 'invoice.payment_succeeded'
      invoice_payment_succeeded
    when 'invoice.payment_failed'
      invoice_payment_failed
    else
      store_unhandled_webhook
    end

    # send a 200 ok to acknowledge receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: { message: 'OK' }, status: 200
  end

  private

  def customer_subscription_deleted
    account = pro_account_from_stripe_event(@stripe_event)
    account.user.remove_role(:pro) if account
  end

  def invoice_payment_succeeded
    subscription_id = @stripe_event.data.object.subscription
    subscription = Stripe::Subscription.retrieve(
      id: subscription_id, expand: ['plan.product']
    )
    plan_name = subscription.plan.product.name
    description = "#{pro_site_name}: #{plan_name}"

    charge_id = @stripe_event.data.object.charge
    Stripe::Charge.update(charge_id, description: description) if charge_id

    payment_intent_id = @stripe_event.data.object.payment_intent
    Stripe::PaymentIntent.update(
      payment_intent_id, description: description
    ) if payment_intent_id
  end

  def invoice_payment_failed
    account = pro_account_from_stripe_event(@stripe_event)
    return unless account&.subscription?

    AlaveteliPro::SubscriptionMailer.payment_failed(account.user).deliver_now
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
    return if @stripe_event.respond_to?(:type)

    msg = "undefined method `type' for #{ @stripe_event.inspect }"
    raise MissingTypeStripeWebhookError, msg
  end

  def notify_exception(error)
    return unless send_exception_notifications?

    ExceptionNotifier.notify_exception(error, env: request.env)
  end

  def filter_hooks
    plans = []
    case @stripe_event.data.object.object
    when 'subscription'
      plans = plan_ids(@stripe_event.data.object.items)
    when 'invoice'
      plans = plan_ids(@stripe_event.data.object.lines)
    end

    # ignore any prices that aren't configured
    plans.delete_if do |price_id|
      !AlaveteliConfiguration.stripe_prices.key?(price_id)
    end

    raise UnknownPlanStripeWebhookError if plans.empty?
  end

  def plan_ids(items)
    items.map { |item| item.plan.id if item.plan }.compact.uniq
  end
end
