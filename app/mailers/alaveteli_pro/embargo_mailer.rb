# -*- encoding : utf-8 -*-
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
      subject = n_(
        "{{count}} request will be made public on {{site_name}} this week",
        "{{count}} requests will be made public on {{site_name}} this week",
        info_requests.count,
        :site_name => AlaveteliConfiguration.site_name.html_safe,
        :count => info_requests.count)
      auto_generated_headers
      mail_user(@user, subject)
    end

    def expired_alert(user, info_requests)
      @user = user
      @info_requests = info_requests
      subject = n_(
        "{{count}} request has been made public on {{site_name}}",
        "{{count}} requests have been made public on {{site_name}}",
        info_requests.count,
        :site_name => AlaveteliConfiguration.site_name.html_safe,
        :count => info_requests.count)
      auto_generated_headers
      mail_user(@user, subject)
    end

    private

    # TODO: these are copied from request_mailer, but it seems like they should
    # be something shared via application_mailer.
    def auto_generated_headers
      headers({
        'Return-Path' => blackhole_email,
        'Reply-To' => pro_contact_from_name_and_email, # not much we can do if the user's email is broken
        'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
        'X-Auto-Response-Suppress' => 'OOF',
      })
    end

    def mail_user(user, subject)
      mail({
        :from => pro_contact_from_name_and_email,
        :to => user.name_and_email,
        :subject => subject,
      })
    end
  end
end
