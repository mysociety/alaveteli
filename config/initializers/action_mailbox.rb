Rails.application.configure do
  config.action_mailbox.storage_service = :inbound_emails
end
