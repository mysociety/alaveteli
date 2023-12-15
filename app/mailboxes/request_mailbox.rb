class RequestMailbox < ApplicationMailbox
  def process
    mail = MailHandler.mail_from_raw_email(inbound_email.source)

    RequestMailer.new.receive(
      mail,
      inbound_email.source,
      inbound_email.origin&.to_sym
    )
  end
end
