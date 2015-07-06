# -*- encoding : utf-8 -*-
class AddUserIndexToInfoRequests < ActiveRecord::Migration
  def self.up
      add_index :info_requests, :user_id
  end

  def self.down
      remove_index :info_requests, :user_id
  end
end
