# -*- encoding : utf-8 -*-
class AddUserIndexToInfoRequests < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :info_requests, :user_id
  end

  def self.down
    remove_index :info_requests, :user_id
  end
end
