# -*- encoding : utf-8 -*-
class CacheOnlyClippedAttachmentText < ActiveRecord::Migration
  def self.up
    remove_column :incoming_messages, :cached_attachment_text
    add_column :incoming_messages, :cached_attachment_text_clipped, :text
  end

  def self.down
    raise "safer not to have reverse migration scripts, and we never use them"
  end
end
