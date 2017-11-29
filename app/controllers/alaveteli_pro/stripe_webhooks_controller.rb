# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController

  before_action :read_event_notification

  class UnhandledStripeWebhookError < StandardError ; end

  def receive
    begin
      case @stripe_event.type
      when 'invoice.payment_failed'
        # ToDo: add specific handler code here, but for now just raise an
        # UnhandledStripeWebhookError
        raise UnhandledStripeWebhookError.new(@stripe_event.type)
      else
        raise UnhandledStripeWebhookError.new(@stripe_event.type)
      end
    rescue UnhandledStripeWebhookError => e
      notify_exception(e)
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: {}, status: 200
  end

  private

  def read_event_notification
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = AlaveteliConfiguration.stripe_webhook_secret
    @stripe_event = nil

    begin
      @stripe_event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload, reject the webhook
      notify_exception(e)
      render json: { error: e.message }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature, reject the webhook
      notify_exception(e)
      render json: { error: e.message }, status: 401
      return
    end
  end

  def notify_exception(error)
    if send_exception_notifications?
      ExceptionNotifier.notify_exception(error, :env => request.env)
    end
  end

end
