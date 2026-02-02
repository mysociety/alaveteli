Rails.application.configure do
  retriever = AlaveteliConfiguration.production_mailer_retriever_method.to_sym
  case retriever
  when :passive, :postfix, :exim, :qmail
    config.action_mailbox.ingress = :relay
  when :mailgun, :mandrill, :postmark, :sendgrid
    config.action_mailbox.ingress = retriever
  else
    config.action_mailbox.ingress = nil
  end

  config.action_mailbox.storage_service = :inbound_emails
end
