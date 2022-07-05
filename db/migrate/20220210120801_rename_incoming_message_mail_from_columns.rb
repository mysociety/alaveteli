class RenameIncomingMessageMailFromColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :incoming_messages, :mail_from, :from_name
    rename_column :incoming_messages, :mail_from_domain, :from_email_domain
  end
end
