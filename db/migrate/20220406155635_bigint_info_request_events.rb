class BigintInfoRequestEvents < ActiveRecord::Migration[6.1]
  def up
    change_column :info_request_events, :comment_id, :bigint
    change_column :info_request_events, :incoming_message_id, :bigint
    change_column :info_request_events, :info_request_id, :bigint
    change_column :info_request_events, :outgoing_message_id, :bigint
    change_column :info_request_events, :id, :bigint
  end

  def down
    change_column :info_request_events, :id, :integer
    change_column :info_request_events, :outgoing_message_id, :integer
    change_column :info_request_events, :info_request_id, :integer
    change_column :info_request_events, :incoming_message_id, :integer
    change_column :info_request_events, :comment_id, :integer
  end
end
