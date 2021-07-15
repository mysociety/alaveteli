class DraftProfilePhoto < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_column :profile_photos, :draft, :boolean, :default => false, :null => false
  end

  def self.down
    raise "No reverse migration"
  end
end
