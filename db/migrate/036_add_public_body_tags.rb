# -*- encoding : utf-8 -*-
class AddPublicBodyTags < ActiveRecord::Migration
    def self.up
        create_table :public_body_tags do |t|
            t.column :public_body_id, :integer, :null => false
            t.column :name, :text, :null => false
            t.column :created_at, :datetime, :null => false
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE public_body_tags ADD CONSTRAINT fk_public_body_tags_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"
        end

        # MySQL cannot index text blobs like this
        # TODO: perhaps should change :name to be a :string
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            add_index :public_body_tags, [:public_body_id, :name], :unique => true
        end
    end

    def self.down
        drop_table :public_body_tags
    end
end

