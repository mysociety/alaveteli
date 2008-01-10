class AddFollowupToOutgoingMessage < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :incoming_message_followup_id, :integer
  end

  def self.down
    drop_column :outgoing_messages, :incoming_message_followup_id
  end
end
