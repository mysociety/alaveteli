class AddTrackThingsUniqueIndices < ActiveRecord::Migration
    def self.up
        add_index :track_things, [:tracking_user_id, :track_query], :unique => true
        execute "create unique index track_things_sent_emails_unique_index on track_things_sent_emails(track_thing_id, coalesce(info_request_event_id, -1), coalesce(user_id, -1), coalesce(public_body_id, -1))"
    end

    def self.down
        remove_index :track_things, [:tracking_user_id, :track_query]
        execute "drop index track_things_sent_emails_unique_index"
    end
end
