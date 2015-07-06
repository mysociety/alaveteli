# -*- encoding : utf-8 -*-
require "securerandom"

class AddApiKeyToPublicBodies < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :api_key, :string
    
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute <<-SQL
      update public_bodies
      set api_key = encode(decode(
          lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
        ||lpad(to_hex(floor(random()*256) :: integer), 2, '0')
      , 'hex'), 'base64')
      SQL
    else
      PublicBody.find_each do |pb|
          pb.api_key = SecureRandom.base64(33)
          pb.save!
      end
    end
    
    change_column_null :public_bodies, :api_key, false
  end

  def self.down
    remove_column :public_bodies, :api_key
  end
end
