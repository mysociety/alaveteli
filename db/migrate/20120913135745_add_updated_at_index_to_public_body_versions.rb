# -*- encoding : utf-8 -*-
class AddUpdatedAtIndexToPublicBodyVersions < ActiveRecord::Migration
  def self.up
    add_index :public_body_versions, :updated_at
  end

  def self.down
    remove_index :public_body_versions, :updated_at
  end
end
