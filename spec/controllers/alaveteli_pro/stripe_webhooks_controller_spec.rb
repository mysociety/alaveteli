require 'spec_helper'
require 'stripe_mock'

RSpec.describe AlaveteliPro::StripeWebhooksController, feature: [:alaveteli_pro, :pro_pricing] do
  describe '#receive' do
    let(:config_secret) { 'whsec_secret' }
    let(:signing_secret) { config_secret }
    let(:stripe_helper) { StripeMock.create_test_helper }

    let(:product) { stripe_helper.create_product }

    let(:stripe_customer) do
      Stripe::Customer.create(source: stripe_helper.generate_card_token,
                              currency: 'gbp')
    end

    let(:stripe_plan) do
      stripe_helper.create_plan(
        id: 'test', name: 'Test', product: product.id,
        amount: 10, currency: 'gbp'
      )
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

    let(:payload) do
      stripe_event.to_hash
    end

    def send_request
      request.headers.merge!(
        signed_headers(payload: payload, signing_secret: signing_secret)
      )
      post :receive, params: payload
    end

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
      send_request
      expect(response).to be_successful
    end

    context 'the secret is not in the request' do
      it 'returns a 401 Unauthorized response' do
        post :receive, params: payload
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = '(Stripe::SignatureVerificationError) "Unable to extract ' \
                   'timestamp and signatures'
        post :receive, params: payload
        mail = deliveries.first
        expect(mail.subject).to include(expected)
      end

      it 'includes the error message in the message body' do
        post :receive, params: payload
        expect(response.body).
          to eq('{"error":"Unable to extract timestamp and signatures ' \
                'from header"}')
      end
    end

    context 'the secret_key does not match' do
      let(:signing_secret) { 'whsec_fake' }

      before do
        send_request
      end

      it 'returns 401 Unauthorized response' do
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = '(Stripe::SignatureVerificationError) "No signatures ' \
                   'found matching the expected'
        mail = deliveries.first
        expect(mail.subject).to include(expected)
      end

      it 'includes the error message in the message body' do
        expect(response.body).
          to eq('{"error":"No signatures found matching the expected ' \
                'signature for payload"}')
      end
    end

    context 'receiving an unhandled notification type' do
      before do
        stripe_event.type = 'custom.unhandle_event'
      end

      it 'stores unhandled webhook' do
        expect { send_request }.to change(Webhook, :count).by(1)
      end
    end

    context 'the timestamp is stale (possible replay attack)' do
      let!(:stale_headers) do
        signed = signed_headers(payload: payload,
                                signing_secret: signing_secret,
                                timestamp: 1.hour.ago)
        request.headers.merge!(signed)
      end

      before do
        request.headers.merge! stale_headers
        post :receive, params: payload
      end

      it 'returns a 401 Unauthorized response' do
        expect(response.status).to eq(401)
      end

      it 'sends an exception email' do
        expected = 'Timestamp outside the tolerance zone'
        mail = deliveries.first
        expect(mail.subject).to include(expected)
      end
    end

    context 'the notification type is missing' do
      let(:payload) do
        { id: '1234' }
      end

      before do
        send_request
      end

      it 'returns a 400 Bad Request response' do
        expect(response.status).to eq(400)
      end

      it 'sends an exception email' do
        expected = 'AlaveteliPro::StripeWebhooksController::' \
                    'MissingTypeStripeWebhookError'
        mail = deliveries.first
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
          send_request
          expect(response.status).to eq(200)
          expect(response.body).
            to match('Does not appear to be one of our plans')
        end

        it 'does not store unhandled webhook' do
          expect { send_request }.to_not change(Webhook, :count)
        end
      end

      context 'the webhook is for a matching namespaced plan' do
        let(:stripe_plan) do
          stripe_helper.create_plan(
            id: 'WDTK-test', name: 'Test', product: product.id,
            amount: 10, currency: 'gbp'
          )
        end

        let(:stripe_event) do
          StripeMock.mock_webhook_event(
            'invoice.payment_succeeded',
            lines: paid_invoice.lines,
            currency: 'gbp',
            charge: paid_invoice.charge,
            subscription: paid_invoice.subscription
          )
        end

        it 'returns a 200 OK response' do
          send_request
          expect(response.status).to eq(200)
          expect(response.body).to match('OK')
        end
      end

      context 'the webhook data does not have namespaced plans' do
        let(:stripe_event) do
          StripeMock.mock_webhook_event('invoice.payment_succeeded')
        end

        it 'does not raise an error when trying to filter on plan name' do
          signed =
            signed_headers(payload: payload, signing_secret: signing_secret)
          request.headers.merge!(signed)
          expect {
            post :receive, params: payload
          }.not_to raise_error
        end
      end
    end

    describe 'a payment fails' do
      let(:stripe_event) do
        StripeMock.mock_webhook_event('invoice.payment_failed')
      end

      let!(:user) do
        _user = FactoryBot.create(:pro_user)
        _user.pro_account.stripe_customer_id = stripe_event.data.object.customer
        _user.pro_account.save!
        _user
      end

      before do
        send_request
      end

      it 'handles the event' do
        expect(response.status).to eq(200)
      end

      it 'notifies the user that their payment failed' do
        mail = deliveries.first
        expect(mail.subject).to match(/Payment failed/)
        expect(mail.to).to include(user.email)
      end
    end

    describe 'a customer moves to a new billing period' do
      let(:stripe_event) do
        StripeMock.mock_webhook_event('subscription-renewed')
      end

      it 'handles the event' do
        send_request
        expect(response.status).to eq(200)
      end

      it 'stores unhandled webhook' do
        expect { send_request }.to change(Webhook, :count).by(1)
      end
    end

    describe 'a trial ends' do
      let(:stripe_event) do
        StripeMock.mock_webhook_event('trial-ended-first-payment-failed')
      end

      it 'handles the event' do
        send_request
        expect(response.status).to eq(200)
      end

      it 'stores unhandled webhook' do
        expect { send_request }.to change(Webhook, :count).by(1)
      end
    end

    describe 'a customer cancels' do
      let(:stripe_event) do
        StripeMock.mock_webhook_event('subscription-cancelled')
      end

      it 'handles the event' do
        send_request
        expect(response.status).to eq(200)
      end

      it 'stores unhandled webhook' do
        expect { send_request }.to change(Webhook, :count).by(1)
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
        send_request
        expect(user.reload.is_pro?).to be false
      end
    end

    describe 'updating the Stripe charge description when a payment succeeds' do
      before do
        send_request
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
