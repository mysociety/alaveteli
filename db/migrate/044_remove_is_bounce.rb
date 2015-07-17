# -*- encoding : utf-8 -*-
class RemoveIsBounce < ActiveRecord::Migration
  def self.up
    remove_column :incoming_messages, :is_bounce
  end

  def self.down
    add_column :incoming_messages, :is_bounce, :boolean, :default => false
  end
end
