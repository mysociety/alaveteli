# -*- encoding : utf-8 -*-
class AddRawEmailIndexToIncomingMessages < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :incoming_messages, :raw_email_id
  end

  def self.down
    remove_index :incoming_messages, :raw_email_id
  end
end
