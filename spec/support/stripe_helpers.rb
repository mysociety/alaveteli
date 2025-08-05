# -*- encoding : utf-8 -*-
def signed_headers(signing_secret: nil, payload: nil, timestamp: Time.zone.now)
  raise ArgumentError, "must provide signing_secret key" unless signing_secret
  raise ArgumentError, "must provide payload key" unless payload

  payload_data = payload.to_json

  secret = Stripe::Webhook::Signature.compute_signature(
    timestamp,
    payload_data,
    signing_secret
  )

  signature = Stripe::Webhook::Signature.generate_header(timestamp, secret)

  {
    'HTTP_STRIPE_SIGNATURE' => signature,
    'CONTENT_TYPE' => 'application/json'
  }
end
