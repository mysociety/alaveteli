# -*- encoding : utf-8 -*-
class AddPublicBodyIndexToInfoRequests < ActiveRecord::Migration
  def self.up
      add_index :info_requests, :public_body_id
  end

  def self.down
      remove_index :info_requests, :public_body_id
  end
end
