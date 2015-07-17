# -*- encoding : utf-8 -*-
class AddTrackThingsUniqueIndices < ActiveRecord::Migration
  def self.up
    add_index :track_things, [:tracking_user_id, :track_query], :unique => true
    # GRRR - this index confuses Rails migrations, and it makes part of the index but not all
    # of it for the schema.rb, and hence in test databases, and the test databases fail.
    # I guess the query in ./activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
    # needs improving to not detect indices with complex components, rather than detect part of them.
    #execute "create unique index track_things_sent_emails_unique_index on track_things_sent_emails(track_thing_id, coalesce(info_request_event_id, -1), coalesce(user_id, -1), coalesce(public_body_id, -1))"
    #
    # I tried altering config.active_record.schema_format to :sql in config/environment.rb, but
    # got all sorts of other problems with the test user not being a database super user, so gave up again.
  end

  def self.down
    remove_index :track_things, [:tracking_user_id, :track_query]
    #execute "drop index track_things_sent_emails_unique_index"
  end
end
