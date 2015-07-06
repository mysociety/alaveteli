# -*- encoding : utf-8 -*-
class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :track_things_sent_emails, :track_thing_id
  end

  def self.down
    remove_index :track_things_sent_emails, :track_thing_id
  end
end
