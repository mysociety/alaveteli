# -*- encoding : utf-8 -*-
class CreatePublicBodies < ActiveRecord::Migration
  def self.up
    create_table :public_bodies do |t|
      t.column :name, :text
      t.column :short_name, :text
      # address for making initial FOI requests
      t.column :request_email, :text
      # address for complaining about an FOI request
      t.column :complaint_email, :text
    end
  end

  def self.down
    drop_table :public_bodies
  end
end
