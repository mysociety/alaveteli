# -*- encoding : utf-8 -*-
class AddCachedMainText < ActiveRecord::Migration
  def self.up
        add_column :incoming_messages, :cached_main_body_text, :text
  end

  def self.down
        remove_column :incoming_messages, :cached_main_body_text
  end
end
