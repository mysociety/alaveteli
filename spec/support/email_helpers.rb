def receive_incoming_mail(filename_or_string = nil, **kwargs)
  kwargs[:from] ||= 'geraldinequango@localhost'
  mail = get_fixture_mail(filename_or_string, **kwargs)

  if kwargs[:info_request]
    kwargs[:info_request].receive(
      mail,
      rejected_reason: kwargs[:rejected_reason],
      override_stop_new_responses: kwargs[:override_stop_new_responses] || false
    )

  else
    ActionMailbox::InboundEmail.create_and_extract_message_id!(
      mail.raw_source, status: :processing
    )&.route
  end

  mail
end

def get_fixture_mail(filename_or_string = nil, **kwargs)
  filename_or_string ||= <<~EML
    From: EMAIL_FROM
    Subject: Basic Email

    Hello, World
  EML

  content = load_file_fixture(filename_or_string) || filename_or_string
  content = gsub_addresses(content, **kwargs)
  Mail.from_source(content)
end

def parse_all_incoming_messages
  IncomingMessage.find_each(&:parse_raw_email)
end

def load_mail_server_logs(log)
  batch = MailServerLogDone.create(filename: 'spec', last_stat: Time.zone.now)
  mta_log_type = AlaveteliConfiguration.mta_log_type.to_sym
  io_stream = StringIO.new(log)
  case mta_log_type
  when :exim
    MailServerLog.load_exim_log_data(io_stream, batch)
  when :postfix
    MailServerLog.load_postfix_log_data(io_stream, batch)
  else
    raise "Unexpected MTA type: #{ mta_log_type }"
  end
end

def gsub_addresses(content, **kwargs)
  kwargs.slice(*%i[to from cc bcc envelope_to]).
    transform_keys { |k| "EMAIL_#{k.to_s.upcase}" }.
    reduce(content) { |c, (k, v)| c.gsub(k, v) }
end

def build_incoming_message_mail(im)
  mail = Mail.new

  mail.to = im.info_request.incoming_email rescue ''
  mail.from = im.read_attribute(:from_email)
  mail.subject = im.read_attribute(:subject)
  mail.date = im.read_attribute(:sent_at)
  mail.body = im.cached_main_body_text_unfolded

  im.foi_attachments.each do |a|
    if a.persisted?
      content = a.file.download
    else
      # NOTE: this uses a private API
      io = a.attachment_changes['file'].attachable[:io]
      content = io.read
      io.rewind
    end

    mail.add_file filename: a.filename, content: content
  end

  mail
end

def rebuild_raw_emails(info_request)
  info_request.incoming_messages.each do |im|
    im.raw_email.data = build_incoming_message_mail(im)
    im.save!
  end
end
