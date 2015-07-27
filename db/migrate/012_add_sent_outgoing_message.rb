# -*- encoding : utf-8 -*-
class AddSentOutgoingMessage < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :sent_at, :datetime
  end

  def self.down
  end
end
