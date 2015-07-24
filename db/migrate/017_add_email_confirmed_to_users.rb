# -*- encoding : utf-8 -*-
class AddEmailConfirmedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :users, :email_confirmed
  end
end
