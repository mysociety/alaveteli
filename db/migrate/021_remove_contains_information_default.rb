class RemoveContainsInformationDefault < ActiveRecord::Migration
  def self.up
        change_column :incoming_messages, :contains_information, :boolean, :default => nil
  end

  def self.down
        change_column :incoming_messages, :contains_information, :boolean, :default => false
  end
end
