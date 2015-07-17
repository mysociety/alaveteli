# -*- encoding : utf-8 -*-
class AddIsBounceToIncomingMessages < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :is_bounce, :boolean, :default => false
    IncomingMessage.update_all "is_bounce = 'f'"
  end

  def self.down
    remove_column :incoming_messages, :is_bounce
  end
end
