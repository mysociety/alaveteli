# -*- encoding : utf-8 -*-
class AddProfilePhoto < ActiveRecord::Migration
  def self.up
    create_table :profile_photos do |t|
      t.column :data, :binary, :null => false
      t.column :user_id, :integer, :null => false
    end

    add_column :users, :profile_photo_id, :integer, :null => true

    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE profile_photos ADD CONSTRAINT fk_profile_photos_user FOREIGN KEY (user_id) REFERENCES users(id)"
      execute "ALTER TABLE users ADD CONSTRAINT fk_users_profile_photo FOREIGN KEY (profile_photo_id) REFERENCES profile_photos(id)"
    end
  end

  def self.down
    remove_column :users, :profile_photo_id
    drop_table :profile_photos
  end
end
