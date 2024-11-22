# models/embargo_mailer.rb:
# Alerts relating to embargoes.
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
module AlaveteliPro
  class EmbargoMailer < ApplicationMailer
    def self.alert_expiring
      expiring_info_requests =
        InfoRequest.
          embargo_expiring.
            where(use_notifications: false).
              group_by(&:user)

      expiring_info_requests.each do |user, info_requests|
        info_requests.reject! do |info_request|
          alert_event_id = info_request.last_embargo_set_event.id
          UserInfoRequestSentAlert.where(
            info_request_id: info_request.id,
            user_id: user.id,
            alert_type: 'embargo_expiring_1',
            info_request_event_id: alert_event_id).exists?
        end
        next if info_requests.empty?

        expiring_alert(user, info_requests).deliver_now
        info_requests.each do |info_request|
          alert_event_id = info_request.last_embargo_set_event.id
          UserInfoRequestSentAlert.create(
            user: user,
            info_request: info_request,
            alert_type: 'embargo_expiring_1',
            info_request_event_id: alert_event_id)
        end
      end
    end

    def self.alert_expired
      expired_info_requests =
        InfoRequest.
          embargo_expired_today.
            where(use_notifications: false).
              group_by(&:user)

      expired_info_requests.each do |user, info_requests|
        info_requests.reject! do |info_request|
          alert_event_id = info_request.last_embargo_expire_event.id
          UserInfoRequestSentAlert.where(
            info_request_id: info_request.id,
            user_id: user.id,
            alert_type: 'embargo_expired_1',
            info_request_event_id: alert_event_id).exists?
        end
        next if info_requests.empty?

        expired_alert(user, info_requests).deliver_now
        info_requests.each do |info_request|
          alert_event_id = info_request.last_embargo_expire_event.id
          UserInfoRequestSentAlert.create(
            user: user,
            info_request: info_request,
            alert_type: 'embargo_expired_1',
            info_request_event_id: alert_event_id)
        end
      end
    end

    def expiring_alert(user, info_requests)
      @user = user
      @info_requests = info_requests
      mail_user(
        @user,
        subject: -> { n_(
          "{{count}} request will be made public on {{site_name}} this week",
          "{{count}} requests will be made public on {{site_name}} this week",
          info_requests.count,
          site_name: site_name.html_safe,
          count: info_requests.count
        ) }
      )
    end

    def expired_alert(user, info_requests)
      @user = user
      @info_requests = info_requests
      mail_user(
        @user,
        subject: -> { n_(
          "{{count}} request has been made public on {{site_name}}",
          "{{count}} requests have been made public on {{site_name}}",
          info_requests.count,
          site_name: site_name.html_safe,
          count: info_requests.count
        ) }
      )
    end
  end
end
