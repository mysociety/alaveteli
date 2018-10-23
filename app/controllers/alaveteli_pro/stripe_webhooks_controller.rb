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

  def receive
    begin
      Webhook.new(
        payload: request.body.read,
        signature: request.headers['HTTP_STRIPE_SIGNATURE']
      ).process

    rescue Webhook::UnhandledTypeError => ex
      notify_exception(ex)
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: { message: 'OK' }, status: 200
  end

  private

  def notify_exception(error)
    return unless send_exception_notifications?

    ExceptionNotifier.notify_exception(error, env: request.env)
  end
end
