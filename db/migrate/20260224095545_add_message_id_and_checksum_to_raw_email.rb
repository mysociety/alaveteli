class AddMessageIdAndChecksumToRawEmail < ActiveRecord::Migration[8.0]
  def change
    add_column :raw_emails, :message_id, :string
    add_column :raw_emails, :message_checksum, :string
  end
end
