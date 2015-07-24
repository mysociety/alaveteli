# -*- encoding : utf-8 -*-
class RemoveRedundantRawEmailColumns < ActiveRecord::Migration
  def self.up
    remove_column :raw_emails, :data_text
    remove_column :raw_emails, :data_binary
  end
  def self.down
  end
end
