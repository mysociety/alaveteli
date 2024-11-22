# models/request_mailer.rb:
# Alerts relating to requests.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RequestMailer < ApplicationMailer
  include AlaveteliFeatures::Helpers

  before_action :set_footer_template,
                only: [
                  :new_response, :overdue_alert, :very_overdue_alert,
                  :new_response_reminder_alert, :old_unclassified_updated,
                  :not_clarified_alert, :comment_on_alert,
                  :comment_on_alert_plural
                ]

  # Used when an FOI officer uploads a response from their web browser - this is
  # the "fake" email used to store in the same format in the database as if they
  # had emailed it.
  def fake_response(info_request, from_user, message_body, attachment_name, attachment_content)
    @message_body = message_body

    if !attachment_name.nil? && !attachment_content.nil?
      content_type = AlaveteliFileTypes.filename_to_mimetype(attachment_name) || 'application/octet-stream'

      attachments[attachment_name] = { content: attachment_content,
                                      content_type: content_type }
    end

    mail(from: from_user.name_and_email,
         to: info_request.incoming_name_and_email,
         subject: info_request.email_subject_followup(html: false))
  end

  # Used when a response is uploaded using the API
  def external_response(info_request, message_body, sent_at, attachment_hashes)
    @message_body = message_body

    attachment_hashes.each do |attachment_hash|
      attachments[attachment_hash[:filename]] = { content: attachment_hash[:body],
                                                 content_type: attachment_hash[:content_type] }
    end

    mail(from: blackhole_email,
         to: info_request.incoming_name_and_email,
         date: sent_at)
  end

  # Incoming message arrived for a request, but new responses have been stopped.
  def stopped_responses(info_request, email, _raw_email_data)
    headers('Return-Path' => blackhole_email,   # we don't care about bounces, likely from spammers
            'Auto-Submitted' => 'auto-replied') # http://tools.ietf.org/html/rfc3834

    @info_request = info_request
    @contact_email = AlaveteliConfiguration.contact_email

    mail(to: email.from_addrs[0].to_s,
         from: contact_from_name_and_email,
         reply_to: contact_from_name_and_email,
         subject: _("Your response to an FOI request was not delivered"))
  end

  # An FOI response is outside the scope of the system, and needs admin attention
  def requires_admin(info_request, set_by = nil, message = "")
    user = set_by || info_request.user
    @reported_by = user
    @url = request_url(info_request)
    @info_request = info_request
    @message = message

    set_reply_to_headers('Reply-To' => user.name_and_email)

    # From is an address we control so that strict DMARC senders don't get refused
    mail(from: MailHandler.address_from_name_and_email(
                    user.name,
                    blackhole_email
                  ),
         to: contact_for_user(user),
         subject: _("FOI response requires admin ({{reason}}) - " \
                        "{{request_title}}",
                       reason: info_request.described_state,
                       request_title: info_request.title.html_safe))
  end

  # Tell the requester that a new response has arrived
  def new_response(info_request, incoming_message)
    @incoming_message = incoming_message
    @info_request = info_request

    mail_user(
      info_request.user,
      subject: -> {
        _("New response to your FOI request - {{request_title}}",
          request_title: info_request.title.html_safe)
      },
      charset: "UTF-8"
    )
  end

  # Tell the requester that the public body is late in replying
  def overdue_alert(info_request, user)
    @url = respond_to_last_url(info_request)
    @info_request = info_request

    mail_user(
      user,
      subject: -> { _(
        "Delayed response to your FOI request - {{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
  end

  # Tell the requester that the public body is very late in replying
  def very_overdue_alert(info_request, user)
    @url = respond_to_last_url(info_request)
    @info_request = info_request

    mail_user(
      user,
      subject: -> { _(
        "You're long overdue a response to your FOI request - " \
        "{{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
  end

  # Tell the requester that they need to say if the new response
  # contains info or not
  def new_response_reminder_alert(info_request, incoming_message)
    target = show_request_url(info_request.url_title,
                              anchor: 'describe_state_form_1',
                              only_path: true)
    @url = signin_url(r: target)
    @incoming_message = incoming_message
    @info_request = info_request

    mail_user(
      info_request.user,
      subject: -> { _(
        "Please update the status of your request - {{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
  end

  # Tell the requester that someone updated their old unclassified request
  def old_unclassified_updated(info_request)
    @url = request_url(info_request)
    @info_request = info_request

    mail_user(
      info_request.user,
      subject: -> { _("Someone has updated the status of your request") }
    )
  end

  # Tell the requester that they need to clarify their request
  def not_clarified_alert(info_request, incoming_message)
    respond_url = new_request_incoming_followup_url(
      info_request.url_title,
      incoming_message_id: incoming_message.id,
      anchor: 'followup'
    )
    @url = respond_url
    @incoming_message = incoming_message
    @info_request = info_request

    mail_user(
      info_request.user,
      subject: -> { _(
        "Clarify your FOI request - {{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
  end

  # Tell requester that somebody add an annotation to their request
  def comment_on_alert(info_request, comment)
    @comment = comment
    @info_request = info_request
    @url = comment_url(comment)

    mail_user(
      info_request.user,
      subject: -> { _(
        "Somebody added a note to your FOI request - {{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
  end

  # Tell requester that somebody added annotations to more than one of
  # their requests
  def comment_on_alert_plural(info_request, count, earliest_unalerted_comment)
    @count = count
    @info_request = info_request
    @url = comment_url(earliest_unalerted_comment)

    mail_user(
      info_request.user,
      subject: -> { _(
        "Some notes have been added to your FOI request - {{request_title}}",
        request_title: info_request.title.html_safe
      ) }
    )
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
  def self.receive(raw_email, source = :mailin)
    unless logger.nil?
      logger.debug "Received mail from #{source}:\n #{raw_email}"
    end
    mail = MailHandler.mail_from_raw_email(raw_email)
    new.receive(mail, raw_email, source)
  end

  # Find which info requests the email is for
  def requests_matching_email(email)
    addresses = MailHandler.get_all_addresses(email)
    InfoRequest.matching_incoming_email(addresses)
  end

  def send_to_holding_pen(email, raw_email, opts)
    opts[:rejected_reason] =
      _("Could not identify the request from the email address")
    request = InfoRequest.holding_pen_request
    request.receive(email, raw_email, opts)
  end

  # Member function, called on the new class made in self.receive above
  def receive(email, raw_email, source = :mailin)
    opts = { source: source }

    # Only check mail that doesn't have spam in the header
    return if SpamAddress.spam?(MailHandler.get_all_addresses(email))

    # Find exact matches for info requests
    exact_info_requests = requests_matching_email(email)

    if exact_info_requests.count > 0
      # Go through each exact info request and deliver the email
      exact_info_requests.each do |info_request|
        info_request.receive(email, raw_email, opts)
      end

      return
    end

    # If there are no exact matches, find any guessed requests
    guessed_info_requests = Guess.guessed_info_requests(email)

    if guessed_info_requests.count == 1
      # If there one guess automatically redeliver the email to that and log it
      # as an event
      info_request = guessed_info_requests.first
      info_request.log_event(
        'redeliver_incoming',
        editor: 'automatic',
        destination_request: info_request
      )
      info_request.receive(email, raw_email, opts)

    else
      # Otherwise we send the mail to the holding pen
      send_to_holding_pen(email, raw_email, opts)
    end
  end

  # Send email alerts for overdue requests
  def self.alert_overdue_requests
    info_requests = InfoRequest.where("described_state = 'waiting_response'
                AND awaiting_description = ?
                AND user_id is not null
                AND use_notifications = ?
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
                ) IS NULL", false, false).includes(:user)

    info_requests.each do |info_request|
      alert_event_id = info_request.last_event_forming_initial_request.id
      # Only overdue requests
      calculated_status = info_request.calculate_status
      if %w[waiting_response_overdue waiting_response_very_overdue].include?(calculated_status)
        if calculated_status == 'waiting_response_overdue'
          alert_type = 'overdue_1'
        elsif calculated_status == 'waiting_response_very_overdue'
          alert_type = 'very_overdue_1'
        else
          raise "unknown request status"
        end

        # For now, just to the user who created the request
        sent_already = UserInfoRequestSentAlert.
          where("alert_type = ? " \
                 "AND user_id = ? " \
                 "AND info_request_id = ? " \
                 "AND info_request_event_id = ?",
                 alert_type,
                 info_request.user_id,
                 info_request.id,
                 alert_event_id).
            first
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
              RequestMailer.
                overdue_alert(
                  info_request,
                  info_request.user
                ).deliver_now
            elsif calculated_status == 'waiting_response_very_overdue'
              RequestMailer.
                very_overdue_alert(
                  info_request,
                  info_request.user
                ).deliver_now
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
    AlaveteliConfiguration.new_response_reminder_after_days.each_with_index do |days, i|
      alert_new_response_reminders_internal(days, "new_response_reminder_#{i+1}")
    end
  end

  def self.alert_new_response_reminders_internal(days_since, type_code)
    info_requests = InfoRequest.
      where_old_unclassified(days_since).
        where(use_notifications: false).
          order(:id).
            includes(:user)

    info_requests.each do |info_request|
      alert_event_id = info_request.get_last_public_response_event_id
      last_response_message = info_request.get_last_public_response
      if alert_event_id.nil?
        raise "internal error, no last response while making alert new " \
                "response reminder, request id " + info_request.id.to_s
      end
      # To the user who created the request
      sent_already = UserInfoRequestSentAlert.
        where("alert_type = ? " \
               "AND user_id = ? " \
               "AND info_request_id = ? " \
               "AND info_request_event_id = ?",
               type_code,
               info_request.user_id,
               info_request.id,
               alert_event_id).
          first
      if sent_already.nil?
        # Alert not yet sent for this user
        store_sent = UserInfoRequestSentAlert.new
        store_sent.info_request = info_request
        store_sent.user = info_request.user
        store_sent.alert_type = type_code
        store_sent.info_request_event_id = alert_event_id
        # TODO: uses same template for reminder 1 and reminder 2 right now.
        RequestMailer.
          new_response_reminder_alert(
            info_request,
            last_response_message
          ).deliver_now
        store_sent.save!
      end
    end
  end

  # Send email alerts for requests which need clarification. Goes out 3 days
  # after last update of event.
  def self.alert_not_clarified_request
    info_requests = InfoRequest.
                      where("awaiting_description = ?
                             AND described_state = 'waiting_clarification'
                             AND info_requests.updated_at < ?
                             AND use_notifications = ?",
                             false,
                             Time.zone.now - 3.days,
                             false
                            ).
                      includes(:user).order(:id)
    info_requests.each do |info_request|
      alert_event_id = info_request.get_last_public_response_event_id
      last_response_message = info_request.get_last_public_response
      next if alert_event_id.nil?

      # To the user who created the request
      sent_already = UserInfoRequestSentAlert.
        where("alert_type = 'not_clarified_1'
               AND user_id = ?
               AND info_request_id = ?
               AND info_request_event_id = ?",
               info_request.user_id,
               info_request.id,
               alert_event_id).
          first
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
          RequestMailer.not_clarified_alert(
            info_request,
            last_response_message
          ).deliver_now
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
    conditions = <<-EOF.strip_heredoc
    info_requests.id in (
      SELECT info_request_id
      FROM info_request_events
      WHERE event_type = 'comment'
      AND created_at > (now() - '1 month'::interval)
    )
    EOF

    info_requests =
      InfoRequest.
        includes(info_request_events: :user_info_request_sent_alerts).
          where(conditions).
            order(:id).merge(InfoRequestEvent.order(:created_at)).
              references(:info_request_events)

    info_requests.each do |info_request|
      next if info_request.is_external?

      # Count number of new comments to alert on
      earliest_unalerted_comment_event = nil
      last_comment_event = nil
      count = 0
      info_request.info_request_events.reverse.each do |e|
        # alert on comments, which were not made by the user who originally made the request
        if e.event_type == 'comment' && e.comment.user_id != info_request.user_id
          last_comment_event = e if last_comment_event.nil?

          alerted_for = e.user_info_request_sent_alerts.
            where("alert_type = 'comment_1'
                    AND user_id = ?",
                    info_request.user_id).
              first
          if alerted_for.nil?
            count += 1
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
          RequestMailer.comment_on_alert_plural(
            info_request,
            count,
            earliest_unalerted_comment_event.comment
          ).deliver_now
        elsif count == 1
          RequestMailer.comment_on_alert(
            info_request,
            last_comment_event.comment
          ).deliver_now
        else
          raise "internal error"
        end
        store_sent.save!
      end
    end
  end

  private

  def set_footer_template
    @footer_template = 'default'
  end
end
