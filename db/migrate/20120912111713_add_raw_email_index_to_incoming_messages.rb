# -*- encoding : utf-8 -*-
class AddRawEmailIndexToIncomingMessages < ActiveRecord::Migration
  def self.up
    add_index :incoming_messages, :raw_email_id
  end

  def self.down
    remove_index :incoming_messages, :raw_email_id
  end
end
