class BigintIncomingMessages < ActiveRecord::Migration[6.1]
  def up
    change_column :incoming_messages, :info_request_id, :bigint
    change_column :incoming_messages, :raw_email_id, :bigint
    change_column :incoming_messages, :id, :bigint
  end

  def down
    change_column :incoming_messages, :id, :integer
    change_column :incoming_messages, :raw_email_id, :integer
    change_column :incoming_messages, :info_request_id, :integer
  end
end
