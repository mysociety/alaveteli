class AddCounterToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :counting_something, :integer, :default => 0
  end

  def self.down
    remove_column :items, :countering_something
  end
end
