# -*- encoding : utf-8 -*-
class CreateInfoRequests < ActiveRecord::Migration
  def self.up
    create_table :info_requests do |t|
        t.column :title,   :text
        t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :info_requests
  end
end
