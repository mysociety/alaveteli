# -*- encoding : utf-8 -*-
class AddAttachmentText < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :cached_attachment_text, :text
  end

  def self.down
    remove_column :incoming_messages, :cached_attachment_text
  end
end
