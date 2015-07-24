# -*- encoding : utf-8 -*-
class ExtendIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :sent_at, :time
    add_column :incoming_messages, :subject, :text
    add_column :incoming_messages, :safe_mail_from, :text
    add_column :incoming_messages, :mail_from_domain, :text
    add_column :incoming_messages, :valid_to_reply_to, :boolean
  end

  def self.down
    remove_column :incoming_messages, :sent_at
    remove_column :incoming_messages, :subject
    remove_column :incoming_messages, :safe_mail_from
    remove_column :incoming_messages, :mail_from_domain
    remove_column :incoming_messages, :valid_to_reply_to
  end
end
