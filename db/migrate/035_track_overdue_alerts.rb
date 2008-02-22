class TrackOverdueAlerts < ActiveRecord::Migration
    def self.up
        create_table :user_info_request_sent_alerts do |t|
            t.column :user_id, :integer, :null => false
            t.column :info_request_id, :integer, :null => false

            t.column :alert_type, :string, :null => false
        end

        execute "ALTER TABLE user_info_request_sent_alerts ADD CONSTRAINT fk_info_request_sent_alerts_user FOREIGN KEY (user_id) REFERENCES users(id)"
        execute "ALTER TABLE user_info_request_sent_alerts ADD CONSTRAINT fk_info_request_sent_alerts_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
     end

    def self.down
        execute "ALTER TABLE user_info_request_sent_alerts DROP CONSTRAINT fk_info_request_sent_alerts_user"
        execute "ALTER TABLE user_info_request_sent_alerts DROP CONSTRAINT fk_info_request_sent_alerts_info_request"
        drop_table :user_info_request_sent_alerts
    end
end
