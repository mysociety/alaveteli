# -*- encoding : utf-8 -*-
class AddFollowupToOutgoingMessage < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :outgoing_messages, :incoming_message_followup_id, :integer
  end

  def self.down
    remove_column :outgoing_messages, :incoming_message_followup_id
  end
end
