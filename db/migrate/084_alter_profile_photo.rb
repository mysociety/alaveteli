class AlterProfilePhoto < ActiveRecord::Migration
    def self.up
        remove_column :profile_photos, :user_id
    end

    def self.down
        raise "Reverse migrations not supported"
    end
end
