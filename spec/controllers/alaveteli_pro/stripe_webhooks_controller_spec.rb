# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'stripe_mock'

describe AlaveteliPro::StripeWebhooksController do

  describe '#receive' do

    let(:config_secret) { 'whsec_secret' }
    let(:signing_secret) { config_secret }

    let(:stripe_event) do
      StripeMock.mock_webhook_event('customer.subscription.deleted')
    end

    before do
      AlaveteliFeatures.backend.enable(:pro_pricing)
      config = MySociety::Config.load_default
      config['STRIPE_WEBHOOK_SECRET'] = config_secret
      config['STRIPE_NAMESPACE'] = ''
      StripeMock.start
    end

    after do
      AlaveteliFeatures.backend.disable(:pro_pricing)
      StripeMock.stop
    end

    def encode_hmac(key, value)
      # this is how Stripe signed headers work, method borrowed from:
      # https://github.com/stripe/stripe-ruby/blob/v3.4.1/lib/stripe/webhook.rb#L24-L26
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), key, value)
    end

    let(:payload) { stripe_event.to_s }

    def signed_headers
      timestamp = Time.zone.now.to_i
      secret = encode_hmac(signing_secret, "#{timestamp}.#{payload}")
      {
        'HTTP_STRIPE_SIGNATURE' => "t=#{timestamp},v1=#{secret}",
        'CONTENT_TYPE' => 'application/json'
      }
    end

    it 'returns a successful response for correctly signed headers' do
      with_feature_enabled(:alaveteli_pro) do
        request.headers.merge! signed_headers
        post :receive, payload
        expect(response).to be_success
      end
    end

    context 'the secret is not in the request' do

      it 'returns a 401 Unauthorized response' do
        with_feature_enabled(:alaveteli_pro) do
          post :receive, payload
          expect(response.status).to eq(401)
        end
      end

      it 'sends an exception email' do
        expected = '(Stripe::SignatureVerificationError) "Unable to extract ' \
                   'timestamp and signatures from header'
        with_feature_enabled(:alaveteli_pro) do
          post :receive, payload
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).
            to include(expected)
        end
      end

      it 'includes the error message in the message body' do
        with_feature_enabled(:alaveteli_pro) do
          post :receive, payload
          expect(response.body).
            to eq('{"error":"Unable to extract timestamp and signatures ' \
                  'from header"}')
        end
      end

    end

    context 'the secret_key does not match' do

      let(:signing_secret) { 'whsec_fake' }

      before do
        request.headers.merge! signed_headers
        post :receive, payload
      end

      it 'returns 401 Unauthorized response' do
        with_feature_enabled(:alaveteli_pro) do
          expect(response.status).to eq(401)
        end
      end

      it 'sends an exception email' do
        expected = '(Stripe::SignatureVerificationError) "No signatures ' \
                   'found matching the expected signature for payload'
        with_feature_enabled(:alaveteli_pro) do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).
            to include(expected)
        end
      end

      it 'includes the error message in the message body' do
        with_feature_enabled(:alaveteli_pro) do
          expect(response.body).
            to eq('{"error":"No signatures found matching the expected ' \
                  'signature for payload"}')
        end
      end

    end

    context 'receiving an unhandled notification type' do

      let(:payload) do
        stripe_event.
          to_s.gsub!('customer.subscription.deleted', 'custom.random_event')
      end

      it 'sends an exception email' do
        with_feature_enabled(:alaveteli_pro) do
          request.headers.merge! signed_headers
          post :receive, payload
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/UnhandledStripeWebhookError/)
        end
      end

    end

    context 'the timestamp is stale (possible replay attack)' do

      let!(:stale_headers) do
        time_travel_to(1.hour.ago) { signed_headers }
      end

      before do
        request.headers.merge! stale_headers
        post :receive, payload
      end

      it 'returns a 401 Unauthorized response' do
        with_feature_enabled(:alaveteli_pro) do
          expect(response.status).to eq(401)
        end
      end

      it 'sends an exception email' do
        expected = 'Timestamp outside the tolerance zone'
        with_feature_enabled(:alaveteli_pro) do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to include(expected)
        end
      end

    end

    context 'the notification type is missing' do

      let(:payload) { '{"id": "1234"}' }

      before do
        request.headers.merge! signed_headers
        post :receive, payload
      end

      it 'returns a 400 Bad Request response' do
        with_feature_enabled(:alaveteli_pro) do
          expect(response.status).to eq(400)
        end
      end

      it 'sends an exception email' do
        expected = '(NoMethodError) "undefined method `type\''
        with_feature_enabled(:alaveteli_pro) do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to include(expected)
        end
      end

    end

  end

end
