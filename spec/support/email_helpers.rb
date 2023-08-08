def load_raw_emails_data
  raw_emails_yml = File.join(RSpec.configuration.fixture_path, "raw_emails.yml")
  YAML.load_file(raw_emails_yml).map { |_k,v| v["id"] }.each do |raw_email_id|
    raw_email = RawEmail.find(raw_email_id)
    raw_email.data = load_file_fixture(format("raw_emails/%d.email", raw_email_id))
  end
end

def receive_incoming_mail(email_name_or_string, **kargs)
  kargs[:email_from] ||= 'geraldinequango@localhost'
  content = load_file_fixture(email_name_or_string) || email_name_or_string
  content = gsub_addresses(content, **kargs)
  content = ::Mail::Utilities.binary_unsafe_to_crlf(content)
  RequestMailer.receive(content)
end

def get_fixture_mail(filename, email_to = nil, email_from = nil)
  content = load_file_fixture(filename)
  content = gsub_addresses(content, email_from: email_from, email_to: email_to)
  MailHandler.mail_from_raw_email(content)
end

def parse_all_incoming_messages
  IncomingMessage.find_each(&:parse_raw_email!)
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

def gsub_addresses(content, **kargs)
  content.gsub!('EMAIL_TO', kargs[:email_to]) if kargs[:email_to]
  content.gsub!('EMAIL_FROM', kargs[:email_from]) if kargs[:email_from]
  content.gsub!('EMAIL_CC', kargs[:email_cc]) if kargs[:email_cc]
  content.gsub!('EMAIL_BCC', kargs[:email_bcc]) if kargs[:email_bcc]
  if kargs[:email_envelope_to]
    content.gsub!('EMAIL_ENVELOPE_TO', kargs[:email_envelope_to])
  end
  content
end

def rebuild_raw_emails(info_request)
  info_request.incoming_messages.each do |im|
    mail = Mail.new

    mail.to = info_request.incoming_email
    mail.from = "#{im.from_name} <#{im.from_email}>"
    mail.subject = im.subject
    mail.date = im.sent_at
    mail.body = im.cached_main_body_text_unfolded

    im.foi_attachments.each do |a|
      mail.add_file filename: a.filename, content: a.file.download
    end

    im.raw_email.data = mail
    im.raw_email.save!
  end
end
