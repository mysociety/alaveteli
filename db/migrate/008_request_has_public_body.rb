class RequestHasPublicBody < ActiveRecord::Migration
  def self.up
    add_column :info_requests, :public_body_id, :integer
  end

  def self.down
    remove_column :info_requests, :public_body_id
  end
end
