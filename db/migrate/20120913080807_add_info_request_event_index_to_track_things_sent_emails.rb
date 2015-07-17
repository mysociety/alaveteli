# -*- encoding : utf-8 -*-
class AddInfoRequestEventIndexToTrackThingsSentEmails < ActiveRecord::Migration
  def self.up
    add_index :track_things_sent_emails, :info_request_event_id
  end

  def self.down
    remove_index :track_things_sent_emails, :info_request_event_id
  end
end
