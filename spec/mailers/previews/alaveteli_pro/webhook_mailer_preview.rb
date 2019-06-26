module AlaveteliPro
  class WebhookMailerPreview < ActionMailer::Preview
    def digest
      webhooks = []

      customers = %w(cus_123 cus_456 cus_789)

      10.times do |idx|
        webhooks << FactoryBot.build(:webhook,
                                     created: idx,
                                     customer: customers.sample)
      end

      WebhookMailer.digest(webhooks)
    end
  end
end
