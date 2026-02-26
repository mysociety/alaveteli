module OutgoingMessage::DeliveryStatus
  extend ActiveSupport::Concern

  included do
    STATUS_TYPES = %w(ready sent failed).freeze

    validates_inclusion_of :status, in: STATUS_TYPES
  end

  class_methods do
    def expected_send_errors
      [EOFError,
       IOError,
       Timeout::Error,
       Errno::ECONNRESET,
       Errno::ECONNABORTED,
       Errno::EPIPE,
       Errno::ETIMEDOUT,
       Net::SMTPAuthenticationError,
       Net::SMTPServerBusy,
       Net::SMTPSyntaxError,
       Net::SMTPUnknownError,
       OpenSSL::SSL::SSLError].concat(additional_send_errors)
    end

    def additional_send_errors
      []
    end
  end

  # Without recording the send failure, parts of the public and admin
  # interfaces for the request and authority may become inaccessible.
  def record_email_failure(failure_reason)
    self.last_sent_at = Time.zone.now
    self.status = 'failed'
    save!

    log_event(
      'send_error',
      reason: failure_reason,
      outgoing_message_id: id
    )
    set_info_request_described_state
  end

  def record_email_delivery(to_addrs, message_id, log_event_type = 'sent')
    self.last_sent_at = Time.zone.now
    self.status = 'sent'
    save!

    if message_type == 'followup'
      log_event_type = "followup_#{ log_event_type }"
    end

    log_event(
      log_event_type,
      email: to_addrs,
      outgoing_message_id: id,
      smtp_message_id: message_id
    )
    set_info_request_described_state
  end

  def sendable?
    if status == 'ready'
      if message_type == 'initial_request'
        true
      elsif message_type == 'followup'
        true
      else
        raise "Message id #{id} has type '#{message_type}' which cannot be sent"
      end
    elsif status == 'sent'
      raise "Message id #{id} has already been sent"
    else
      raise "Message id #{id} not in state for sending"
    end
  end

  # Public: Return logged Message-ID attributes for this OutgoingMessage.
  # Note that these are not the MTA ID: https://en.wikipedia.org/wiki/Message-ID
  #
  # Returns an Array
  def smtp_message_ids
    info_request_events.
      order(:created_at).
        map { |event| event.params[:smtp_message_id] }.
          compact.
            map do |smtp_id|
              smtp_id.match(/<(.*)>/) { |m| m.captures.first } || smtp_id
            end
  end

  # Public: Return logged MTA IDs for this OutgoingMessage.
  #
  # Returns an Array
  def mta_ids
    case AlaveteliConfiguration.mta_log_type.to_sym
    when :exim
      exim_mta_ids
    when :postfix
      postfix_mta_ids
    else
      raise 'Unexpected MTA type'
    end
  end

  # Public: Return the MTA logs for this message.
  #
  # Returns an Array.
  def mail_server_logs
    case AlaveteliConfiguration.mta_log_type.to_sym
    when :exim
      exim_mail_server_logs
    when :postfix
      postfix_mail_server_logs
    else
      raise 'Unexpected MTA type'
    end
  end

  def delivery_status
    # If the outgoing status is failed, we won't have mail logs, and know we can
    # present a failed status to the end user.
    if status == 'failed'
      MailServerLog::DeliveryStatus.new(:failed)
    else
      mail_server_logs.map(&:delivery_status).compact.reject(&:unknown?).last ||
        MailServerLog::DeliveryStatus.new(:unknown)
    end
  end

  private

  def exim_mta_ids
    lines = smtp_message_ids.map do |smtp_message_id|
      info_request.
        mail_server_logs.
          where("line ILIKE :q", q: "%#{ smtp_message_id }%").
            where("line ILIKE :marker", marker: "%<=%").
              last.
                try(:line)
    end

    lines.compact.map { |line| line[/\b\w{6}-(?:\w{6}-\w{2}|\w{11}-\w{4})\b/].strip }.compact
  end

  def exim_mail_server_logs
    logs = mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end

    smarthost_mta_ids = logs.flat_map do |log|
      line = log.line(decorate: true)
      if line.delivery_status.try(:delivered?)
        match = line.to_s.match(/C=".*?id=(?<message_id>\w+-\w+-\w+).*"/)
        match[:message_id] if match
      end
    end

    smarthost_mta_ids.compact!

    smarthost_logs = smarthost_mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end

    # Need to call #uniq because the more_logs query pulls out the initial
    # delivery line
    (logs + smarthost_logs).uniq
  end

  def postfix_mta_ids
    lines = smtp_message_ids.map do |smtp_message_id|
      info_request.
        mail_server_logs.
          where("line ILIKE :q", q: "%#{ smtp_message_id }%").
              last.
                try(:line)
    end
    lines.compact.map { |line| line.split(' ')[5].strip.chomp(':') }
  end

  def postfix_mail_server_logs
    mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end
  end
end
