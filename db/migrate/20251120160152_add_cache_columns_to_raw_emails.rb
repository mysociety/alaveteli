class AddCacheColumnsToRawEmails < ActiveRecord::Migration[8.0]
  def change
    add_column :raw_emails, :from_email, :text
    add_column :raw_emails, :from_email_domain, :text
    add_column :raw_emails, :from_name, :text
    add_column :raw_emails, :message_id, :text
    add_column :raw_emails, :sent_at, :timestamp
    add_column :raw_emails, :subject, :text
    add_column :raw_emails, :valid_to_reply_to, :boolean

    add_index :raw_emails, :from_email
    add_index :raw_emails, :from_email_domain
    add_index :raw_emails, :message_id
    add_index :raw_emails, :sent_at
    add_index :raw_emails, :valid_to_reply_to
  end
end
