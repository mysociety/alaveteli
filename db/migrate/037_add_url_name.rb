class AddUrlName < ActiveRecord::Migration
    def self.up
        add_column :public_bodies, :url_name, :text
        add_column :public_body_versions, :url_name, :text

        PublicBody.find(:all).each do |public_body|
            public_body.update_url_name
            public_body.save!
        end
        add_index :public_bodies, :url_name, :unique => true
        change_column :public_bodies, :url_name, :text, :null => false
    end

    def self.down
        remove_column :public_bodies, :url_name
        remove_column :public_body_versions, :url_name
    end
end
