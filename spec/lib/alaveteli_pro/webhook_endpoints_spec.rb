require 'spec_helper'
require 'stripe_mock'

describe AlaveteliPro::WebhookEndpoints do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }

  describe '.webhook_endpoint_url' do
    subject { described_class.webhook_endpoint_url }

    it { is_expected.to match('test.host/pro/subscriptions/stripe-webhook') }

    context 'https is disabled' do
      it { is_expected.to match(/^http:/) }
    end

    context 'https is enabled' do
      it 'uses the http protocol' do
        allow(AlaveteliConfiguration).to receive(:force_ssl).and_return(true)
        expect(subject).to match(/^https:/)
      end
    end
  end
end
