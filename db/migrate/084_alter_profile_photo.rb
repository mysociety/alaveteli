# -*- encoding : utf-8 -*-
class AlterProfilePhoto < ActiveRecord::Migration
  def self.up
    remove_column :users, :profile_photo_id
  end

  def self.down
    raise "No reverse migration"
  end
end
