module AlaveteliPro
  class AccountMailerPreview < ActionMailer::Preview
    def account_request
      AlaveteliPro::AccountMailer.account_request(request)
    end

    private

    def request
      AlaveteliPro::AccountRequest.new(
        email: 'user@localhost',
        reason: 'This is my reason I want access to AlaveteliPro',
        marketing_emails: true,
        training_emails: true
      )
    end
  end
end
