# -*- encoding : utf-8 -*-
# models/request_mailer.rb:
# Alerts relating to requests.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RequestMailer < ApplicationMailer
  # Used when an FOI officer uploads a response from their web browser - this is
  # the "fake" email used to store in the same format in the database as if they
  # had emailed it.
  def fake_response(info_request, from_user, message_body, attachment_name, attachment_content)
    @message_body = message_body

    if !attachment_name.nil? && !attachment_content.nil?
      content_type = AlaveteliFileTypes.filename_to_mimetype(attachment_name) || 'application/octet-stream'

      attachments[attachment_name] = {:content => attachment_content,
                                      :content_type => content_type}
    end

    mail(:from => from_user.name_and_email,
         :to => info_request.incoming_name_and_email,
         :subject => info_request.email_subject_followup(:html => false))
  end

  # Used when a response is uploaded using the API
  def external_response(info_request, message_body, sent_at, attachment_hashes)
    @message_body = message_body

    attachment_hashes.each do |attachment_hash|
      attachments[attachment_hash[:filename]] = {:content => attachment_hash[:body],
                                                 :content_type => attachment_hash[:content_type]}
    end

    mail(:from => blackhole_email,
         :to => info_request.incoming_name_and_email,
         :date => sent_at)
  end

  # Incoming message arrived for a request, but new responses have been stopped.
  def stopped_responses(info_request, email, raw_email_data)
    headers('Return-Path' => blackhole_email,   # we don't care about bounces, likely from spammers
            'Auto-Submitted' => 'auto-replied') # http://tools.ietf.org/html/rfc3834

    attachments.inline["original.eml"] = raw_email_data

    @info_request = info_request
    @contact_email = AlaveteliConfiguration::contact_email

    mail(:to => email.from_addrs[0].to_s,
         :from => contact_from_name_and_email,
         :reply_to => contact_from_name_and_email,
         :subject => _("Your response to an FOI request was not delivered"))
  end

  # An FOI response is outside the scope of the system, and needs admin attention
  def requires_admin(info_request, set_by = nil, message = "")
    user = set_by || info_request.user
    @reported_by = user
    @url = request_url(info_request)
    @admin_url = admin_request_url(info_request)
    @info_request = info_request
    @message = message

    mail(:from => user.name_and_email,
         :to => contact_from_name_and_email,
         :subject => _("FOI response requires admin ({{reason}}) - {{title}}", :reason => info_request.described_state, :title => info_request.title.html_safe))
  end

  # Tell the requester that a new response has arrived
  def new_response(info_request, incoming_message)
    # Don't use login link here, just send actual URL. This is
    # because people tend to forward these emails amongst themselves.
    @url = incoming_message_url(incoming_message, :cachebust => true)
    @incoming_message, @info_request = incoming_message, info_request

    headers('Return-Path' => blackhole_email,
            'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
            'X-Auto-Response-Suppress' => 'OOF')

    mail(:from => contact_from_name_and_email,
         :to => info_request.user.name_and_email,
         :subject => _("New response to your FOI request - ") + info_request.title.html_safe,
         :charset => "UTF-8",
         # not much we can do if the user's email is broken
         :reply_to => contact_from_name_and_email)
  end

  # Tell the requester that the public body is late in replying
  def overdue_alert(info_request, user)
    respond_url = respond_to_last_url(info_request) + "#followup"

    post_redirect = PostRedirect.new(
      :uri => respond_to_last_url(info_request) + "#followup",
      :user_id => user.id)
    post_redirect.save!
    url = confirm_url(:email_token => post_redirect.email_token)

    @url = confirm_url(:email_token => post_redirect.email_token)
    @info_request = info_request

    auto_generated_headers
    mail_user_with_info_request_title(user, _("Delayed response to your FOI request - "), info_request)
  end

  # Tell the requester that the public body is very late in replying
  def very_overdue_alert(info_request, user)
    respond_url = respond_to_last_url(info_request) + "#followup"

    post_redirect = PostRedirect.new(
      :uri => respond_to_last_url(info_request) + "#followup",
      :user_id => user.id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)
    @info_request = info_request

    auto_generated_headers
    mail_user_with_info_request_title(user, _("You're long overdue a response to your FOI request - "), info_request)
  end

  # Tell the requester that they need to say if the new response
  # contains info or not
  def new_response_reminder_alert(info_request, incoming_message)
    # Make a link going to the form to describe state, and which logs the
    # user in.
    post_redirect = PostRedirect.new(
      :uri => request_url(info_request) + "#describe_state_form_1",
      :user_id => info_request.user.id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)
    @incoming_message = incoming_message
    @info_request = info_request

    auto_generated_headers
    mail_user(info_request.user, _("Was the response you got to your FOI request any good?"))
  end

  # Tell the requester that someone updated their old unclassified request
  def old_unclassified_updated(info_request)
    @url = request_url(info_request)
    @info_request = info_request

    auto_generated_headers
    mail_user(info_request.user, _("Someone has updated the status of your request"))
  end

  # Tell the requester that they need to clarify their request
  def not_clarified_alert(info_request, incoming_message)
    respond_url = show_response_url(:id => info_request.id, :incoming_message_id => incoming_message.id)
    respond_url = respond_url + "#followup"

    post_redirect = PostRedirect.new(
      :uri => respond_url,
      :user_id => info_request.user.id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)
    @incoming_message = incoming_message
    @info_request = info_request

    auto_generated_headers
    mail_user_with_info_request_title(info_request.user, _("Clarify your FOI request - "), info_request)
  end

  # Tell requester that somebody add an annotation to their request
  def comment_on_alert(info_request, comment)
    @comment, @info_request = comment, info_request
    @url = comment_url(comment)

    auto_generated_headers
    mail_user_with_info_request_title(info_request.user, _("Somebody added a note to your FOI request - "), info_request)
  end
  def comment_on_alert_plural(info_request, count, earliest_unalerted_comment)
    @count, @info_request = count, info_request
    @url = comment_url(earliest_unalerted_comment)

    auto_generated_headers
    mail_user_with_info_request_title(info_request.user, _("Some notes have been added to your FOI request - "), info_request)
  end

  # Class function, called by script/mailin with all incoming responses.
  # [ This is a copy (Monkeypatch!) of function from action_mailer/base.rb,
  # but which additionally passes the raw_email to the member function, as we
  # want to record it.
  #
  # That is because we want to be sure we properly record the actual message
  # received in its raw form - so any information won't be lost in a round
  # trip via the mail handler, or by bugs in it, and so we can use something
  # other than TMail at a later date. And so we can offer an option to download the
  # actual original mail sent by the authority in the admin interface (so
  # can check that attachment decoding failures are problems in the message,
  # not in our code). ]
  def self.receive(raw_email)
    logger.info "Received mail:\n #{raw_email}" unless logger.nil?
    mail = MailHandler.mail_from_raw_email(raw_email)
    new.receive(mail, raw_email)
  end

  # Find which info requests the email is for
  def requests_matching_email(email)
    # We deliberately don't use Envelope-to here, so ones that are BCC
    # drop into the holding pen for checking.
    addresses = ((email.to || []) + (email.cc || [])).compact
    reply_info_requests = [] # TODO: should be set?
    addresses.each do |address|
      reply_info_request = InfoRequest.find_by_incoming_email(address)
      reply_info_requests.push(reply_info_request) if reply_info_request
    end
    return reply_info_requests
  end

  # Member function, called on the new class made in self.receive above
  def receive(email, raw_email)
    # Find which info requests the email is for
    reply_info_requests = self.requests_matching_email(email)
    # Nothing found, so save in holding pen
    if reply_info_requests.size == 0
      reason = _("Could not identify the request from the email address")
      request = InfoRequest.holding_pen_request
      request.receive(email, raw_email, false, reason) unless SpamAddress.spam?(email.to)
      return
    end

    spam_action = AlaveteliConfiguration.incoming_email_spam_action
    spam_threshold = AlaveteliConfiguration.incoming_email_spam_threshold
    spam_header = AlaveteliConfiguration.incoming_email_spam_header
    spam_score = email.header[spam_header].try(:value).to_f

    if spam_action && spam_header && spam_threshold && spam_score
      if spam_score > spam_threshold
        case spam_action
        when 'discard'
          # Do nothing. Silently drop spam above the threshold
          return
        when 'holding_pen'
          reason = _("Incoming message has a spam score ({{spam_score}}) " \
                     "above the configured threshold ({{spam_threshold}}).",
                     :spam_score => spam_score,
                     :spam_threshold => spam_threshold)
          request = InfoRequest.holding_pen_request
          request.receive(email, raw_email, false, reason)
          return
        end
      end
    end

    # Send the message to each request, to be archived with it
    for reply_info_request in reply_info_requests
      # If environment variable STOP_DUPLICATES is set, don't send message with same id again
      if ENV['STOP_DUPLICATES']
        if reply_info_request.already_received?(email, raw_email)
          raise "message " + email.message_id + " already received by request"
        end
      end
      reply_info_request.receive(email, raw_email)
    end
  end

  # Send email alerts for overdue requests
  def self.alert_overdue_requests
    info_requests = InfoRequest.find(:all,
                                     :conditions => [
                                       "described_state = 'waiting_response'
                 AND awaiting_description = ?
                 AND user_id is not null
                 AND (SELECT id
                      FROM user_info_request_sent_alerts
                      WHERE alert_type = 'very_overdue_1'
                      AND info_request_id = info_requests.id
                      AND user_id = info_requests.user_id
                      AND info_request_event_id = (SELECT max(id)
                                                   FROM info_request_events
                                                   WHERE event_type in ('sent',
                                                                        'followup_sent',
                                                                        'resent',
                                                                        'followup_resent')
                      AND info_request_id = info_requests.id)
                      ) IS NULL", false
    ],
    :include => [ :user ]
                                    )
    for info_request in info_requests
      alert_event_id = info_request.last_event_forming_initial_request.id
      # Only overdue requests
      calculated_status = info_request.calculate_status
      if ['waiting_response_overdue', 'waiting_response_very_overdue'].include?(calculated_status)
        if calculated_status == 'waiting_response_overdue'
          alert_type = 'overdue_1'
        elsif calculated_status == 'waiting_response_very_overdue'
          alert_type = 'very_overdue_1'
        else
          raise "unknown request status"
        end

        # For now, just to the user who created the request
        sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = ?
                                                                               AND user_id = ?
                                                                               AND info_request_id = ?
                                                                               AND info_request_event_id = ?",
                                                                                 alert_type,
                                                                                 info_request.user_id,
                                                                                 info_request.id,
                                                                                 alert_event_id])
        if sent_already.nil?
          # Alert not yet sent for this user, so send it
          store_sent = UserInfoRequestSentAlert.new
          store_sent.info_request = info_request
          store_sent.user = info_request.user
          store_sent.alert_type = alert_type
          store_sent.info_request_event_id = alert_event_id
          # Only send the alert if the user can act on it by making a followup
          # (otherwise they are banned, and there is no point sending it)
          if info_request.user.can_make_followup?
            if calculated_status == 'waiting_response_overdue'
              RequestMailer.overdue_alert(info_request, info_request.user).deliver
            elsif calculated_status == 'waiting_response_very_overdue'
              RequestMailer.very_overdue_alert(info_request, info_request.user).deliver
            else
              raise "unknown request status"
            end
          end
          store_sent.save!
        end
      end
    end
  end

  # Send email alerts for new responses which haven't been classified. By default,
  # it goes out 3 days after last update of event, then after 10, then after 24.
  def self.alert_new_response_reminders
    AlaveteliConfiguration::new_response_reminder_after_days.each_with_index do |days, i|
      self.alert_new_response_reminders_internal(days, "new_response_reminder_#{i+1}")
    end
  end
  def self.alert_new_response_reminders_internal(days_since, type_code)
    info_requests = InfoRequest.find_old_unclassified(:order => 'info_requests.id',
                                                      :include => [:user],
                                                      :age_in_days => days_since)

    for info_request in info_requests
      alert_event_id = info_request.get_last_public_response_event_id
      last_response_message = info_request.get_last_public_response
      if alert_event_id.nil?
        raise "internal error, no last response while making alert new response reminder, request id " + info_request.id.to_s
      end
      # To the user who created the request
      sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = ? and user_id = ? and info_request_id = ? and info_request_event_id = ?", type_code, info_request.user_id, info_request.id, alert_event_id])
      if sent_already.nil?
        # Alert not yet sent for this user
        store_sent = UserInfoRequestSentAlert.new
        store_sent.info_request = info_request
        store_sent.user = info_request.user
        store_sent.alert_type = type_code
        store_sent.info_request_event_id = alert_event_id
        # TODO: uses same template for reminder 1 and reminder 2 right now.
        RequestMailer.new_response_reminder_alert(info_request, last_response_message).deliver
        store_sent.save!
      end
    end
  end

  # Send email alerts for requests which need clarification. Goes out 3 days
  # after last update of event.
  def self.alert_not_clarified_request
    info_requests = InfoRequest.find(:all, :conditions => [ "awaiting_description = ? and described_state = 'waiting_clarification' and info_requests.updated_at < ?", false, Time.now - 3.days ], :include => [ :user ], :order => "info_requests.id" )
    for info_request in info_requests
      alert_event_id = info_request.get_last_public_response_event_id
      last_response_message = info_request.get_last_public_response
      if alert_event_id.nil?
        raise "internal error, no last response while making alert not clarified reminder, request id " + info_request.id.to_s
      end
      # To the user who created the request
      sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = 'not_clarified_1' and user_id = ? and info_request_id = ? and info_request_event_id = ?", info_request.user_id, info_request.id, alert_event_id])
      if sent_already.nil?
        # Alert not yet sent for this user
        store_sent = UserInfoRequestSentAlert.new
        store_sent.info_request = info_request
        store_sent.user = info_request.user
        store_sent.alert_type = 'not_clarified_1'
        store_sent.info_request_event_id = alert_event_id
        # Only send the alert if the user can act on it by making a followup
        # (otherwise they are banned, and there is no point sending it)
        if info_request.user.can_make_followup?
          RequestMailer.not_clarified_alert(info_request, last_response_message).deliver
        end
        store_sent.save!
      end
    end
  end

  # Send email alert to request submitter for new comments on the request.
  def self.alert_comment_on_request

    # We only check comments made in the last month - this means if the
    # cron jobs broke for more than a month events would be lost, but no
    # matter. I suspect the performance gain will be needed (with an index on updated_at)

    # TODO: the :order part info_request_events.created_at is a work around
    # for a very old Rails bug which means eager loading does not respect
    # association orders.
    #   http://dev.rubyonrails.org/ticket/3438
    #   http://lists.rubyonrails.org/pipermail/rails-core/2006-July/001798.html
    # That that patch has not been applied, despite bribes of beer, is
    # typical of the lack of quality of Rails.

    info_requests = InfoRequest.find(:all,
                                     :conditions => [
                                       "info_requests.id in (
                    select info_request_id
                    from info_request_events
                    where event_type = 'comment'
                    and created_at > (now() - '1 month'::interval)
                )"
    ],
    :include => [ { :info_request_events => :user_info_request_sent_alerts } ],
    :order => "info_requests.id, info_request_events.created_at"
                                    )
    for info_request in info_requests

      next if info_request.is_external?
      # Count number of new comments to alert on
      earliest_unalerted_comment_event = nil
      last_comment_event = nil
      count = 0
      for e in info_request.info_request_events.reverse
        # alert on comments, which were not made by the user who originally made the request
        if e.event_type == 'comment' && e.comment.user_id != info_request.user_id
          last_comment_event = e if last_comment_event.nil?

          alerted_for = e.user_info_request_sent_alerts.find(:first, :conditions => [ "alert_type = 'comment_1' and user_id = ?", info_request.user_id])
          if alerted_for.nil?
            count = count + 1
            earliest_unalerted_comment_event = e
          else
            break
          end
        end
      end

      # Alert needs sending if there are new comments
      if count > 0
        store_sent = UserInfoRequestSentAlert.new
        store_sent.info_request = info_request
        store_sent.user = info_request.user
        store_sent.alert_type = 'comment_1'
        store_sent.info_request_event_id = last_comment_event.id
        if count > 1
          RequestMailer.comment_on_alert_plural(info_request, count, earliest_unalerted_comment_event.comment).deliver
        elsif count == 1
          RequestMailer.comment_on_alert(info_request, last_comment_event.comment).deliver
        else
          raise "internal error"
        end
        store_sent.save!
      end
    end
  end

  private

  def auto_generated_headers
    headers({
      'Return-Path' => blackhole_email,
      'Reply-To' => contact_from_name_and_email, # not much we can do if the user's email is broken
      'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
      'X-Auto-Response-Suppress' => 'OOF',
    })
  end

  def mail_user_with_info_request_title(user, subject, info_request)
    mail_user(user, subject + info_request.title.html_safe)
  end

  def mail_user(user, subject)
    mail({
      :from => contact_from_name_and_email,
      :to => user.name_and_email,
      :subject => subject,
    })
  end

end
