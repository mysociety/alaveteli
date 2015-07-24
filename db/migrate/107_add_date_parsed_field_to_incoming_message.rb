# -*- encoding : utf-8 -*-
class AddDateParsedFieldToIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :last_parsed, :datetime
  end

  def self.down
    remove_column :incoming_messages, :last_parsed
  end
end
