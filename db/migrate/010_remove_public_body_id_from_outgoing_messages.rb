# -*- encoding : utf-8 -*-
class RemovePublicBodyIdFromOutgoingMessages < ActiveRecord::Migration
  def self.up
    remove_column :outgoing_messages, :public_body_id
  end

  def self.down
    add_column :outgoing_messages, :public_body_id, :integer
  end
end
