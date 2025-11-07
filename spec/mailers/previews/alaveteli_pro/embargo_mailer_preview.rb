module AlaveteliPro
  class EmbargoMailerPreview < ActionMailer::Preview
    def expiring_alert
      AlaveteliPro::EmbargoMailer.expiring_alert(user, info_requests)
    end

    def expired_alert
      AlaveteliPro::EmbargoMailer.expired_alert(user, info_requests)
    end

    private

    def user
      User.new(
        name: 'Pro user',
        email: 'pro@localhost'
      )
    end

    def info_requests
      [
        InfoRequest.new(url_title: 'pro_request_1'),
        InfoRequest.new(url_title: 'pro_request_2')
      ]
    end
  end
end
