# -*- encoding : utf-8 -*-
def signed_headers(signing_secret: nil, payload: nil, timestamp: Time.zone.now)
  raise ArgumentError, "must provide signing_secret key" unless signing_secret
  raise ArgumentError, "must provide payload key" unless payload

  timestamp = timestamp.to_i
  payload_data = payload.to_json

  secret =
    Stripe::Webhook::Signature.send(:compute_signature,
                                    "#{timestamp}.#{payload_data}",
                                    signing_secret)

  {
    'HTTP_STRIPE_SIGNATURE' => "t=#{timestamp},v1=#{secret}",
    'CONTENT_TYPE' => 'application/json'
  }
end
