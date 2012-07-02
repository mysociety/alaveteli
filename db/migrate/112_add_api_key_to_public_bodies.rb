require "securerandom"

class AddApiKeyToPublicBodies < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :api_key, :string
    
    PublicBody.find_each do |pb|
        pb.api_key = SecureRandom.base64(32)
        pb.save!
    end
    
    change_column_null :public_bodies, :api_key, false
  end

  def self.down
    remove_column :public_bodies, :api_key
  end
end
