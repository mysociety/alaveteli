# -*- encoding : utf-8 -*-
class ImproveTrackThings < ActiveRecord::Migration
    def self.up
        # SQLite at least needs a default for this
        add_column :track_things, :track_type, :string, :null => false, :default => "internal_error"

        add_column :track_things, :created_at, :datetime
        add_column :track_things, :updated_at, :datetime
        add_column :track_things_sent_emails, :created_at, :datetime
        add_column :track_things_sent_emails, :updated_at, :datetime

        add_column :users, :last_daily_track_email, :datetime
        User.update_all "last_daily_track_email = '2000-01-01'"
        change_column :users, :last_daily_track_email, :datetime, :default => "2000-01-01"
    end

    def self.down
        remove_column :track_things, :track_type

        remove_column :track_things, :created_at
        remove_column :track_things, :updated_at
        remove_column :track_things_sent_emails, :created_at
        remove_column :track_things_sent_emails, :updated_at

        remove_column :users, :last_daily_track_email
    end
end
