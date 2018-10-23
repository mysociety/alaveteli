# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'stripe_mock'

describe AlaveteliPro::StripeWebhooksController, feature: [:alaveteli_pro, :pro_pricing] do

  describe '#receive' do

    let(:config_secret) { 'whsec_secret' }
    let(:signing_secret) { config_secret }
    let(:stripe_helper) { StripeMock.create_test_helper }

    let(:stripe_customer) do
      Stripe::Customer.create(source: stripe_helper.generate_card_token,
                              currency: 'gbp')
    end

    let(:stripe_plan) do
      Stripe::Plan.create(id: 'test',
                          name: 'Test',
                          amount: 10,
                          currency: 'gbp',
                          interval: 'monthly')
    end

    let(:stripe_subscription) do
      Stripe::Subscription.create(customer: stripe_customer,
                                  plan: stripe_plan.id)
    end

    let(:paid_invoice) do
      invoice = Stripe::Invoice.create(
        lines: [
          {
            data: {
              id: stripe_subscription.id,
              subscription_item: stripe_subscription.items.data.first.id,
              amount: stripe_plan.amount,
              currency: stripe_plan.currency,
              type: 'subscription'
            },
            plan: { id: stripe_plan.id, name: stripe_plan.name }
          }
        ],
        subscription: stripe_subscription.id
      )
      invoice.pay
    end

    let(:charge) { Stripe::Charge.retrieve(paid_invoice.charge) }

    let(:stripe_event) do
      StripeMock.mock_webhook_event('customer.subscription.deleted')
    end

    let(:payload) { stripe_event.to_s }

    before do
      allow(AlaveteliConfiguration).to receive(:stripe_namespace).
        and_return('')
      allow(AlaveteliConfiguration).to receive(:stripe_webhook_secret).
        and_return(config_secret)
      StripeMock.start
    end

    after do
      StripeMock.stop
    end

    it 'returns a successful response for correctly signed headers' do
      request.headers.merge! signed_headers
      post :receive, payload
      expect(response).to be_success
    end

    context 'the secret is not in the request' do

      it 'returns a 401 Unauthorized response' do
        post :receive, payload
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = '(Webhook::VerificationError) "Unable to extract ' \
                   'timestamp and signatures from header'
        post :receive, payload
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to include(expected)
      end

      it 'includes the error message in the message body' do
        post :receive, payload
        expect(response.body).
          to eq('{"error":"Unable to extract timestamp and signatures ' \
                'from header"}')
      end

    end

    context 'the secret_key does not match' do

      let(:signing_secret) { 'whsec_fake' }

      before do
        request.headers.merge! signed_headers
        post :receive, payload
      end

      it 'returns 401 Unauthorized response' do
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = '(Webhook::VerificationError) "No signatures ' \
                   'found matching the expected signature for payload'
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to include(expected)
      end

      it 'includes the error message in the message body' do
        expect(response.body).
          to eq('{"error":"No signatures found matching the expected ' \
                'signature for payload"}')
      end

    end

    context 'receiving an unhandled notification type' do

      let(:payload) do
        stripe_event.
          to_s.gsub!('customer.subscription.deleted', 'custom.random_event')
      end

      it 'sends an exception email' do
        request.headers.merge! signed_headers
        post :receive, payload
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Webhook::UnhandledTypeError/)
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
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = 'Timestamp outside the tolerance zone'
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to include(expected)
      end

    end

    context 'the notification type is missing' do

      let(:payload) do
        event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
        event.type = nil
        event.to_s
      end

      before do
        request.headers.merge! signed_headers
        post :receive, payload
      end

      it 'returns a 400 Bad Request response' do
        expect(response.status).to eq(400)
      end

      it 'sends an exception email' do
        expected = '(Webhook::MissingTypeError) "undefined method `type\''
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to include(expected)
      end

    end

    context 'when using namespaced plans' do

      before do
        allow(AlaveteliConfiguration).to receive(:stripe_namespace).
          and_return('WDTK')
      end

      context 'the webhook does not reference our plan namespace' do

        it 'returns a custom 200 response' do
          request.headers.merge! signed_headers
          post :receive, payload
          expect(response.status).to eq(200)
          expect(response.body).
            to match('OK')
        end

        it 'does not send an exception email' do
          request.headers.merge! signed_headers
          post :receive, payload
          expect(ActionMailer::Base.deliveries.count).to eq(0)
        end

      end

      context 'the webhook is for a matching namespaced plan' do
        let(:stripe_plan) do
          Stripe::Plan.create(id: 'WDTK-test',
                              name: 'Test',
                              amount: 10,
                              currency: 'gbp',
                              interval: 'monthly')
        end

        let(:payload) do
          event = StripeMock.mock_webhook_event(
                    'invoice.payment_succeeded',
                    {
                      lines: paid_invoice.lines,
                      currency: 'gbp',
                      charge: paid_invoice.charge,
                      subscription: paid_invoice.subscription
                    }
                  )
          event.to_s
        end

        it 'returns a 200 OK response' do
          request.headers.merge! signed_headers
          post :receive, payload
          expect(response.status).to eq(200)
          expect(response.body).to match('OK')
        end

      end

      context 'the webhook data does not have namespaced plans' do

        let(:payload) do
          StripeMock.mock_webhook_event('invoice.payment_succeeded').to_s
        end

        it 'does not raise an error when trying to filter on plan name' do
          request.headers.merge! signed_headers
          expect{ post :receive, payload }.not_to raise_error
        end

      end

    end

    describe 'a cancelled subscription is deleted at the end of the billing period' do

      let!(:user) do
        _user = FactoryBot.create(:pro_user)
        _user.pro_account.stripe_customer_id = stripe_event.data.object.customer
        _user.pro_account.save!
        _user
      end

      it 'removes the pro role from the associated user' do
        expect(user.is_pro?).to be true
        request.headers.merge! signed_headers
        post :receive, payload
        expect(user.reload.is_pro?).to be false
      end

    end

    describe 'updating the Stripe charge description when a payment succeeds' do

      before do
        request.headers.merge!(signed_headers)
        post :receive, payload
      end

      context 'when there is a charge for an invoice' do
        let(:stripe_event) do
          StripeMock.mock_webhook_event('invoice.payment_succeeded',
                                        charge: paid_invoice.charge,
                                        subscription: stripe_subscription.id)
        end

        it 'updates the charge description with the site and plan name' do
          expect(Stripe::Charge.retrieve(charge.id).description).
            to eq('Alaveteli Professional: Test')
        end

      end

      context 'when there is no charge for an invoice' do
        let(:stripe_event) do
          StripeMock.mock_webhook_event('invoice.payment_succeeded',
                                        charge: nil)
        end

        it 'does not attempt to update the nil charge' do
          expect(response.status).to eq(200)
        end

      end

    end

  end

end

def encode_hmac(key, value)
  # this is how Stripe signed headers work, method borrowed from:
  # https://github.com/stripe/stripe-ruby/blob/v3.4.1/lib/stripe/webhook.rb#L24-L26
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), key, value)
end

def signed_headers
  timestamp = Time.zone.now.to_i
  secret = encode_hmac(signing_secret, "#{timestamp}.#{payload}")
  {
    'HTTP_STRIPE_SIGNATURE' => "t=#{timestamp},v1=#{secret}",
    'CONTENT_TYPE' => 'application/json'
  }
end
