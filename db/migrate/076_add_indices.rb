# -*- encoding : utf-8 -*-
class AddIndices < ActiveRecord::Migration[4.2] # 2.1
  def self.up
    add_index :track_things_sent_emails, :track_thing_id
  end

  def self.down
    remove_index :track_things_sent_emails, :track_thing_id
  end
end
