class RemoveIsBounce < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    remove_column :incoming_messages, :is_bounce
  end

  def self.down
    add_column :incoming_messages, :is_bounce, :boolean, :default => false
  end
end
