# -*- encoding : utf-8 -*-
class VersionPublicBody <  ActiveRecord::Migration[4.2] # 1.2
  def self.up
    PublicBody.create_versioned_table

    add_timestamps(:public_body_versions, :null => false)
  end

  def self.down
    PublicBody.drop_versioned_table
  end
end
