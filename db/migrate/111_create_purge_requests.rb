# -*- encoding : utf-8 -*-
class CreatePurgeRequests < ActiveRecord::Migration
  def self.up
    create_table :purge_requests do |t|
        t.column :url, :string
        t.column :created_at, :datetime, :null => false
        t.column :model, :string, :null => false
        t.column :model_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :purge_requests
  end
end
