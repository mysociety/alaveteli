# -*- encoding : utf-8 -*-
class AddInfoRequestsCountToPublicBodies < ActiveRecord::Migration
  def self.up
      add_column :public_bodies, :info_requests_count, :integer, :null => false, :default => 0

      PublicBody.connection.execute("UPDATE public_bodies
                                     SET info_requests_count = (SELECT COUNT(*) FROM info_requests
                                                                WHERE public_body_id = public_bodies.id);")


  end

  def self.down
      remove_column :public_bodies, :info_requests_count
  end

end
