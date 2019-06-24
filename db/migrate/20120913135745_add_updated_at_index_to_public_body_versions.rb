# -*- encoding : utf-8 -*-
class AddUpdatedAtIndexToPublicBodyVersions <  ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :public_body_versions, :updated_at
  end

  def self.down
    remove_index :public_body_versions, :updated_at
  end
end
