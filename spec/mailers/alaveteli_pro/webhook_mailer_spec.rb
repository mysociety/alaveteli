require 'spec_helper'

RSpec.describe AlaveteliPro::WebhookMailer do
  MockWebhook = Struct.new(:date, :customer_id, :state)

  describe '#digest' do
    let(:webhooks) do
      [
        MockWebhook.new(Time.new(2019, 01, 02), 'cus_123', 'state_b'),
        MockWebhook.new(Time.new(2019, 01, 01), 'cus_123', 'state_a'),
        MockWebhook.new(Time.new(2019, 01, 01), 'cus_456', 'state_a')
      ]
    end

    let(:message) do
      AlaveteliPro::WebhookMailer.digest(webhooks).message
    end

    it 'sends the email to the pro contact address' do
      expect(message.to).to eq [AlaveteliConfiguration.pro_contact_email]
    end

    it 'sends the email from the pro contact address' do
      expect(message.from).to eq [AlaveteliConfiguration.pro_contact_email]
    end

    it 'has a subject including "account request"' do
      expect(message.subject).to match('webhook daily digest')
    end

    it 'includes a list of webhooks by customers and sorted by date' do
      expect(message.body).to include(
        <<~TXT
          * https://dashboard.stripe.com/customers/cus_123
            - state_a
            - state_b
          * https://dashboard.stripe.com/customers/cus_456
            - state_a
        TXT
      )
    end
  end
end
