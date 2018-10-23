# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController
  rescue_from Webhook::ParserError, Webhook::MissingTypeError do |exception|
    notify_exception(exception)
    render json: { error: exception.message }, status: 400
  end

  rescue_from Webhook::VerificationError do |exception|
    notify_exception(exception)
    render json: { error: exception.message }, status: 401
  end

  before_action :filter_hooks

  class UnhandledStripeWebhookError < StandardError ; end

  def receive
    begin
      case webhook.type
      when 'customer.subscription.deleted'
        customer_id = webhook.event.data.object.customer
        if account = ProAccount.find_by(stripe_customer_id: customer_id)
          account.user.remove_role(:pro)
        end
      when 'invoice.payment_succeeded'
        charge_id = webhook.event.data.object.charge

        if charge_id
          charge = Stripe::Charge.retrieve(charge_id)

          subscription_id = webhook.event.data.object.subscription
          subscription = Stripe::Subscription.retrieve(subscription_id)
          plan_name = subscription.plan.name

          charge.description =
            "#{ AlaveteliConfiguration.pro_site_name }: #{ plan_name }"

          charge.save
        end
      else
        raise UnhandledStripeWebhookError.new(webhook.type)
      end
    rescue UnhandledStripeWebhookError => e
      notify_exception(e)
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: { message: 'OK' }, status: 200
  end

  private

  def webhook
    @webhook ||= Webhook.new(
      payload: request.body.read,
      signature: request.headers['HTTP_STRIPE_SIGNATURE']
    )
  end

  def notify_exception(error)
    return unless send_exception_notifications?

    ExceptionNotifier.notify_exception(error, env: request.env)
  end

  # ignore any that don't match our plan namespace
  def filter_hooks
    return unless webhook.plans.empty?

    # accept it so it doesn't get resent but don't process it
    # (and don't generate an exception email for it)
    render json: { message: 'Does not appear to be one of our plans' },
           status: 200
  end
end
