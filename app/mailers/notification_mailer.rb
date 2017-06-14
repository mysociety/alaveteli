# -*- encoding : utf-8 -*-
# models/notification_mailer.rb:
# Emails relating to notifications from the site
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class NotificationMailer < ApplicationMailer
  def self.send_daily_notifications
    done_something = false
    query = "notifications.frequency = ? AND " \
            "notifications.send_after <= ? AND " \
            "notifications.seen_at IS NULL"
    users = User.
      includes(:notifications).
        references(:notifications).
          where(query,
                Notification.frequencies[Notification::DAILY],
                Time.zone.now)

    users.find_each do |user|
      notifications = user.notifications.daily.unseen.order(created_at: :desc)
      NotificationMailer.daily_summary(user, notifications).deliver
      notifications.update_all(seen_at: Time.zone.now)
      done_something = true
    end
    done_something
  end

  def self.send_daily_notifications_loop
    # Run send_daily_notifications in an endless loop, sleeping when there is
    # nothing to do
    while true
      sleep_seconds = 1
      while !send_daily_notifications
        sleep sleep_seconds
        sleep_seconds *= 2
        sleep_seconds = 300 if sleep_seconds > 300
      end
    end
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
