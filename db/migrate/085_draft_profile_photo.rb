# -*- encoding : utf-8 -*-
class DraftProfilePhoto < ActiveRecord::Migration
    def self.up
        add_column :profile_photos, :draft, :boolean, :default => false, :null => false
    end

    def self.down
        raise "No reverse migration"
    end
end
