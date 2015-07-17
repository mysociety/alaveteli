# -*- encoding : utf-8 -*-
class AddIndicesTrackSent < ActiveRecord::Migration
  def self.up
    add_index :track_things_sent_emails, :created_at
  end

  def self.down
    remove_index :track_things_sent_emails, :created_at
  end
end
