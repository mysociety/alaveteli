# -*- encoding : utf-8 -*-
class ChangeSafeMailFromToMailFrom < ActiveRecord::Migration
  def self.up
    remove_column :incoming_messages, :safe_mail_from
    add_column :incoming_messages, :mail_from, :text
  end

  def self.down
    remove_column :incoming_messages, :mail_from
    add_column :incoming_messages, :safe_mail_from, :text
  end
end
