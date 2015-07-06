# -*- encoding : utf-8 -*-
class AddCensorTable < ActiveRecord::Migration
    def self.up
        create_table :censor_rules do |t|
            t.column :info_request_id, :integer
            t.column :user_id, :integer
            t.column :public_body_id, :integer

            t.column :text, :text, :null => false
            t.column :replacement, :text, :null => false

            t.column :last_edit_editor, :string, :null => false
            t.column :last_edit_comment, :text, :null => false

            t.column :created_at, :datetime, :null => false
            t.column :updated_at, :datetime, :null => false
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE censor_rules ADD CONSTRAINT fk_censor_rules_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
            execute "ALTER TABLE censor_rules ADD CONSTRAINT fk_censor_rules_user FOREIGN KEY (user_id) REFERENCES users(id)"
            execute "ALTER TABLE censor_rules ADD CONSTRAINT fk_censor_rules_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"
        end
    end

    def self.down
        drop_table :censor_rules
    end
end

