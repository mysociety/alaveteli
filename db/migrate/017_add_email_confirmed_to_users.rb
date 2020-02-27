# -*- encoding : utf-8 -*-
class AddEmailConfirmedToUsers < ActiveRecord::Migration[4.2] # 1.2
  def self.up
    add_column :users, :email_confirmed, :boolean, default: false
  end

  def self.down
    remove_column :users, :email_confirmed
  end
end
