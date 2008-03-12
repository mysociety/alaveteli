class UniqueUserUrls < ActiveRecord::Migration
    def self.up
        # do last registered ones first, so the last ones get rubbish URLs
        User.find(:all, :order => "id desc").each do |user|
            user.update_url_name
            user.save!
        end
        remove_index :users, :url_name
        add_index :users, :url_name, :unique => true
    end

    def self.down
        remove_index :users, :url_name
        add_index :users, :url_name, :unique => false
    end

end
