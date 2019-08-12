module AlaveteliPro
  class WebhookMailerPreview < ActionMailer::Preview
    def digest
      webhooks = []

      customers = %w(cus_123 cus_456 cus_789)

      fixtures = %w(
        coupon-code-applied
        coupon-code-revoked
        plan-changed
        subscription-cancelled
        subscription-reactivated
        subscription-renewal-failure
        subscription-renewal-repeated-failure
        subscription-renewed-after-failure
        subscription-renewed
        trial-cancelled
        trial-ended-first-payment-failed
        trial-extended
      )

      10.times do |idx|
        webhooks << FactoryBot.build(:webhook,
                                     created: idx,
                                     customer: customers.sample,
                                     fixture: fixtures.sample)
      end

      WebhookMailer.digest(webhooks)
    end
  end
end
