# -*- encoding : utf-8 -*-
def load_raw_emails_data
    raw_emails_yml = File.join(RSpec.configuration.fixture_path, "raw_emails.yml")
    for raw_email_id in YAML::load_file(raw_emails_yml).map{|k,v| v["id"]} do
        raw_email = RawEmail.find(raw_email_id)
        raw_email.data = load_file_fixture("raw_emails/%d.email" % [raw_email_id])
    end
end

def receive_incoming_mail(email_name, email_to, email_from = 'geraldinequango@localhost')
    email_name = file_fixture_name(email_name)
    content = File.open(email_name, 'rb') { |f| f.read }
    content.gsub!('EMAIL_TO', email_to)
    content.gsub!('EMAIL_FROM', email_from)
    RequestMailer.receive(content)
end

def get_fixture_mail(filename)
    MailHandler.mail_from_raw_email(load_file_fixture(filename))
end

def parse_all_incoming_messages
    IncomingMessage.find(:all).each{ |x| x.parse_raw_email! }
end
