# -*- encoding : utf-8 -*-
# models/notification_mailer.rb:
# Emails relating to notifications from the site
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class NotificationMailer < ApplicationMailer
  def instant_notification(notification)
    event_type = notification.info_request_event.event_type
    method = "#{event_type}_notification".to_sym
    self.send(method, notification)
  end

  def response_notification(notification)
    @info_request = notification.info_request_event.info_request
    @incoming_message = notification.info_request_event.incoming_message

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    mail(
      :from => contact_for_user(@info_request.user),
      :to => @info_request.user.name_and_email,
      :subject => _("New response to your FOI request - {{request_title}}",
                    :request_title => @info_request.title.html_safe),
      :charset => "UTF-8",
      :template_name => 'new_response'
    )
  end

  def daily_summary(user, notifications)
    @user = user
    @grouped_notifications = notifications.group_by do |n|
      info_request = n.info_request_event.info_request
      if info_request.info_request_batch_id.present?
        info_request.info_request_batch
      else
        info_request
      end
    end

    set_reply_to_headers(user)
    set_auto_generated_headers

    mail_user(
      user,
      _("Your daily request summary from {{pro_site_name}}",
        pro_site_name: AlaveteliConfiguration.pro_site_name)
    )
  end
end
