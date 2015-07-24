# -*- encoding : utf-8 -*-
class AddInfoRequestIdIndexToIncomingAndOutgoingMessages < ActiveRecord::Migration
  def self.up
    add_index :incoming_messages, :info_request_id
    add_index :outgoing_messages, :info_request_id
  end

  def self.down
    remove_index :incoming_messages, :info_request_id
    remove_index :outgoing_messages, :info_request_id
  end
end
