# -*- encoding : utf-8 -*-
class AddIncomingMessageIndexToOutgoingMessages < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :outgoing_messages, :incoming_message_followup_id
  end

  def self.down
    remove_index :outgoing_messages, :incoming_message_followup_id
  end
end
