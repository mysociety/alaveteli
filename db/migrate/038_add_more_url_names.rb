class AddMoreUrlNames < ActiveRecord::Migration
    def self.up
        add_column :users, :url_name, :text

        User.find(:all).each do |user|
            user.update_url_name
            user.save!
        end
        add_index :users, :url_name
        change_column :users, :url_name, :text, :null => false
    end

    def self.down
        remove_column :users, :url_name
    end
end

