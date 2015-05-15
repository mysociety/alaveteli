# -*- encoding : utf-8 -*-
class CreateIncomingMessages < ActiveRecord::Migration
  def self.up
    create_table :incoming_messages do |t|
      t.column :info_request_id, :integer
      t.column :raw_data, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :incoming_messages
  end
end
