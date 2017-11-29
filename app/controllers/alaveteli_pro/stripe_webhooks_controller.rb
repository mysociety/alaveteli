# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController

  before_action :read_event_notification

  def receive
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
      render json: { error: e.message }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature, reject the webhook
      render json: { error: e.message }, status: 401
      return
    end
  end

end
