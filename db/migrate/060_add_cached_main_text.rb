class AddCachedMainText < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :incoming_messages, :cached_main_body_text, :text
  end

  def self.down
    remove_column :incoming_messages, :cached_main_body_text
  end
end
