# -*- encoding : utf-8 -*-
def signed_headers(signing_secret: nil, payload: nil, timestamp: Time.zone.now)
  raise ArgumentError, "must provide signing_secret key" unless signing_secret
  raise ArgumentError, "must provide payload key" unless payload

  timestamp = timestamp.to_i
  secret = encode_hmac(signing_secret, "#{timestamp}.#{payload}")

  {
    'HTTP_STRIPE_SIGNATURE' => "t=#{timestamp},v1=#{secret}",
    'CONTENT_TYPE' => 'application/json'
  }
end

def encode_hmac(key, value)
  # this is how Stripe signed headers work, method borrowed from:
  # https://github.com/stripe/stripe-ruby/blob/v3.4.1/lib/stripe/webhook.rb#L24-L26
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), key, value)
end
