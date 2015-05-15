# -*- encoding : utf-8 -*-
class AddComments < ActiveRecord::Migration
    def self.up
        create_table :comments do |t|
            t.column :user_id, :integer, :null => false
            t.column :comment_type, :string, :null => false, :default => "internal_error"

            t.column :info_request_id, :integer

            t.column :body, :text, :null => false
            t.column :visible, :boolean, :default => true, :null => false

            t.column :created_at, :datetime, :null => false
            t.column :updated_at, :datetime, :null => false
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE comments ADD CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id)"

            execute "ALTER TABLE comments ADD CONSTRAINT fk_comments_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
        end

        add_column :info_request_events, :comment_id, :integer
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE info_request_events ADD CONSTRAINT fk_info_request_events_comment_id FOREIGN KEY (comment_id) REFERENCES comments(id)"
        end
    end

    def self.down
        drop_table :comments
        remove_column :info_request_events, :comment_id
    end
end
