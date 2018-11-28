class AddIncomingMessagesCountToInfoRequests < ActiveRecord::Migration
  def change
    add_column :info_requests, :incoming_messages_count, :integer, default: 0
  end
end
