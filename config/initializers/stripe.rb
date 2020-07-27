# -*- encoding : utf-8 -*-
Stripe.api_key = AlaveteliConfiguration.stripe_secret_key
Stripe.api_version = '2017-01-27'
Stripe.enable_telemetry = false

module Stripe
  ##
  # An array of events that we want to enable for our webhook endpoint
  def self.webhook_events
    %w(
      customer.subscription.deleted invoice.payment_succeeded
      invoice.payment_failed customer.subscription.updated
    )
  end
end
