class RemoveIncomingMessagesRawEmailForeignKey < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :incoming_messages, :raw_emails
  end
end
