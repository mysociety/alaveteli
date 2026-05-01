Rails.application.configure do
  retriever = AlaveteliConfiguration.production_mailer_retriever_method.to_sym
  case retriever
  when :passive, :postfix, :exim, :qmail
    config.action_mailbox.ingress = :relay
  when :mailgun, :mandrill, :postmark, :sendgrid
    config.action_mailbox.ingress = retriever
  else
    raise "Unsupported PRODUCTION_MAILER_RETRIEVER_METHOD: " \
          "#{ retriever.inspect }. Valid values are: passive, postfix, " \
          "exim, qmail, mailgun, mandrill, postmark, sendgrid."
  end

  config.action_mailbox.storage_service = :inbound_emails
end
