# -*- encoding : utf-8 -*-
class AddIncomingMessageIndexToOutgoingMessages < ActiveRecord::Migration
  def self.up
      add_index :outgoing_messages, :incoming_message_followup_id
  end

  def self.down
      remove_index :outgoing_messages, :incoming_message_followup_id
  end
end
