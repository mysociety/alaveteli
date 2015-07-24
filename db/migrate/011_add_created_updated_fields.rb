# -*- encoding : utf-8 -*-
class AddCreatedUpdatedFields < ActiveRecord::Migration
  def self.up
    # InfoRequest
    add_column :info_requests, :created_at, :datetime
    add_column :info_requests, :updated_at, :datetime

    # Outgoing Message already has it

    # PublicBody
    add_column :public_bodies, :created_at, :datetime
    add_column :public_bodies, :updated_at, :datetime

    # PublicBodyVersion doesn't need it

    # Session
    add_column :sessions, :created_at, :datetime

    # Users
    add_column :users, :created_at, :datetime
    add_column :users, :updated_at, :datetime

  end

  def self.down
    remove_column :info_requests, :created_at
    remove_column :info_requests, :updated_at

    remove_column :public_bodies, :created_at
    remove_column :public_bodies, :updated_at

    remove_column :sessions, :created_at

    remove_column :users, :created_at
    remove_column :users, :updated_at
  end
end
