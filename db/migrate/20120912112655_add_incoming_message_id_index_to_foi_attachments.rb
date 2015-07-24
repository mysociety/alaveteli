# -*- encoding : utf-8 -*-
class AddIncomingMessageIdIndexToFoiAttachments < ActiveRecord::Migration
  def self.up
    add_index :foi_attachments, :incoming_message_id
  end

  def self.down
    remove_index :foi_attachments, :incoming_message_id
  end
end
