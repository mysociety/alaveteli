# -*- encoding : utf-8 -*-
class TrackOverdueAlerts < ActiveRecord::Migration
    def self.up
        create_table :user_info_request_sent_alerts do |t|
            t.column :user_id, :integer, :null => false
            t.column :info_request_id, :integer, :null => false

            t.column :alert_type, :string, :null => false
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE user_info_request_sent_alerts ADD CONSTRAINT fk_info_request_sent_alerts_user FOREIGN KEY (user_id) REFERENCES users(id)"
            execute "ALTER TABLE user_info_request_sent_alerts ADD CONSTRAINT fk_info_request_sent_alerts_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
        end
     end

    def self.down
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE user_info_request_sent_alerts DROP CONSTRAINT fk_info_request_sent_alerts_user"
            execute "ALTER TABLE user_info_request_sent_alerts DROP CONSTRAINT fk_info_request_sent_alerts_info_request"
        end
        drop_table :user_info_request_sent_alerts
    end
end
