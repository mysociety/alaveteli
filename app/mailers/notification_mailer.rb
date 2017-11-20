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
            "notifications.seen_at IS NULL AND " \
            "notifications.expired = ?"
    users = User.
      includes(:notifications).
        references(:notifications).
          where(query,
                Notification.frequencies[Notification::DAILY],
                Time.zone.now,
                false)
    users.find_each do |user|
      notifications = user.
        notifications.
          daily.
            unseen.
              where(expired: false).
                order(created_at: :desc)
      notifications = Notification.reject_and_mark_expired(notifications)
      NotificationMailer.daily_summary(user, notifications).deliver_now
      Notification.
        where(id: notifications.map(&:id)).
        update_all(seen_at: Time.zone.now)
      done_something = true
    end
    done_something
  end

  def self.send_instant_notifications
    done_something = false
    notifications = Notification.
      instantly.
        unseen.
          where(expired: false).
            order(:created_at)
    notifications = Notification.reject_and_mark_expired(notifications)
    notifications.each do |notification|
      NotificationMailer.instant_notification(notification).deliver_now
      notification.seen_at = Time.zone.now
      notification.save!
      done_something = true
    end
    done_something
  end

  def self.send_notifications
    sent_instant_notifications = self.send_instant_notifications
    sent_daily_notifications = self.send_daily_notifications
    sent_instant_notifications || sent_daily_notifications
  end

  def self.send_notifications_loop
    # Run send_notifications in an endless loop, sleeping when there is
    # nothing to do
    while true
      sleep_seconds = 1
      while !send_notifications
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

    subject = _("New response to your FOI request - {{request_title}}",
                :request_title => @info_request.title.html_safe)
    mail_user(@info_request.user,
              subject,
              template_name: 'response_notification')
  end

  def embargo_expiring_notification(notification)
    @info_request = notification.info_request_event.info_request

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    subject = _(
      "Your FOI request - {{request_title}} will be made public on " \
      "{{site_name}} this week",
      :request_title => @info_request.title.html_safe,
      :site_name => AlaveteliConfiguration.site_name.html_safe)

    mail_user(@info_request.user,
              subject,
              template_name: 'embargo_expiring_notification')
  end

  def embargo_expired_notification(notification)
    @info_request = notification.info_request_event.info_request

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    subject = _(
      "Your FOI request - {{request_title}} has been made public on " \
      "{{site_name}}",
      :request_title => @info_request.title.html_safe,
      :site_name => AlaveteliConfiguration.site_name.html_safe)

    mail_user(@info_request.user,
              subject,
              template_name: 'embargo_expired_notification')
  end

  def overdue_notification(notification)
    @info_request = notification.info_request_event.info_request

    post_redirect = PostRedirect.new(
      :uri => respond_to_last_url(@info_request, :anchor => "followup"),
      :user_id => @info_request.user.id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    subject = _("Delayed response to your FOI request - {{request_title}}",
                :request_title => @info_request.title.html_safe)

    mail_user(@info_request.user,
              subject,
              template_name: 'overdue_notification')
  end

  def very_overdue_notification(notification)
    @info_request = notification.info_request_event.info_request

    post_redirect = PostRedirect.new(
      :uri => respond_to_last_url(@info_request, :anchor => "followup"),
      :user_id => @info_request.user.id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    subject = _("You're long overdue a response to your FOI request " \
                "- {{request_title}}",
                :request_title => @info_request.title.html_safe)

    mail_user(@info_request.user,
              subject,
              template_name: 'very_overdue_notification')
  end
end
