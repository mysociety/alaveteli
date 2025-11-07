module AlaveteliPro
  class SubscriptionMailerPreview < ActionMailer::Preview
    def payment_failed
      AlaveteliPro::SubscriptionMailer.payment_failed(user)
    end

    private

    def user
      User.new(
        name: 'Pro user',
        email: 'pro@localhost'
      )
    end
  end
end
