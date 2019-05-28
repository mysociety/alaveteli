# -*- encoding : utf-8 -*-
class AllowNullProfilePhotoUser <  ActiveRecord::Migration[4.2] # 2.3
  def self.up
    change_column :profile_photos, :user_id, :integer, :null => true
  end

  def self.down
    raise "No reverse migration"
  end
end
