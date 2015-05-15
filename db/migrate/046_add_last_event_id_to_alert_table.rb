# -*- encoding : utf-8 -*-
class AddLastEventIdToAlertTable < ActiveRecord::Migration
    def self.up
        add_column :user_info_request_sent_alerts, :info_request_event_id, :integer, :default => nil
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE user_info_request_sent_alerts ADD CONSTRAINT fk_user_info_request_sent_alert_info_request_event FOREIGN KEY (info_request_event_id) REFERENCES info_request_events(id)"
            # The coalesce is because null values are considered not equal in SQL, and we want them
            # to be considered equal for the purposes of this index.
            execute "create unique index user_info_request_sent_alerts_unique_index on user_info_request_sent_alerts (user_id, info_request_id, alert_type, coalesce(info_request_event_id, -1))"
        end
     end

    def self.down
        remove_column :user_info_request_sent_alerts, :info_request_event_id
    end
end
