class AddIncomingMessagesCountToInfoRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :info_requests, :incoming_messages_count, :integer, default: 0
  end
end
