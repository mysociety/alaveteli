# -*- encoding : utf-8 -*-
class TrackThings < ActiveRecord::Migration
    def self.up
       create_table :track_things do |t|
            t.column :tracking_user_id, :integer, :null => false
            t.column :track_query, :string, :null => false

            # optional foreign key links, for displaying people who are tracking this on pages
            t.column :info_request_id, :integer, :default => nil
            t.column :tracked_user_id, :integer, :default => nil
            t.column :public_body_id, :integer, :default => nil

            t.column :track_medium, :string, :null => false
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE track_things ADD CONSTRAINT fk_track_request_tracking_user FOREIGN KEY (tracking_user_id) REFERENCES users(id)"
            execute "ALTER TABLE track_things ADD CONSTRAINT fk_track_request_tracked_user FOREIGN KEY (tracked_user_id) REFERENCES users(id)"
            execute "ALTER TABLE track_things ADD CONSTRAINT fk_track_request_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
            execute "ALTER TABLE track_things ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"
        end

        create_table :track_things_sent_emails do |t|
            t.column :track_thing_id, :integer, :null => false

            t.column :info_request_event_id, :integer, :default => nil
            t.column :user_id, :integer, :default => nil
            t.column :public_body_id, :integer, :default => nil
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE track_things_sent_emails ADD CONSTRAINT fk_track_request_info_request_event FOREIGN KEY (info_request_event_id) REFERENCES info_request_events(id)"
            execute "ALTER TABLE track_things_sent_emails ADD CONSTRAINT fk_track_request_user FOREIGN KEY (user_id) REFERENCES users(id)"
            execute "ALTER TABLE track_things_sent_emails ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (user_id) REFERENCES users(id)"
        end
    end

    def self.down
        drop_table :track_things
        drop_table :track_things_sent_emails
    end
end
