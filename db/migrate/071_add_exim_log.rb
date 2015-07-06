# -*- encoding : utf-8 -*-
class AddEximLog < ActiveRecord::Migration
    def self.up
        create_table :exim_logs do |t|
            t.column :exim_log_done_id, :integer
            t.column :info_request_id, :integer

            t.column :order, :integer, :null => false
            t.column :line, :text, :null => false

            t.column :created_at, :datetime, :null => false
            t.column :updated_at, :datetime, :null => false
        end

        create_table :exim_log_dones do |t|
            t.column :filename, :text, :null => false, :unique => true
            t.column :last_stat, :datetime, :null => false

            t.column :created_at, :datetime, :null => false
            t.column :updated_at, :datetime, :null => false
        end
        add_index :exim_log_dones, :last_stat

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE exim_logs ADD CONSTRAINT fk_exim_log_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
            execute "ALTER TABLE exim_logs ADD CONSTRAINT fk_exim_log_done FOREIGN KEY (exim_log_done_id) REFERENCES exim_log_dones(id)"
        end
    end

    def self.down
        drop_table :exim_log_dones
        drop_table :exim_logs
    end
end

