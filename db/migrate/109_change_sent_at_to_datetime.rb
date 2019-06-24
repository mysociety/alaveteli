# -*- encoding : utf-8 -*-
class ChangeSentAtToDatetime <  ActiveRecord::Migration[4.2] # 2.3
  def self.up
    remove_column :incoming_messages, :sent_at
    add_column :incoming_messages, :sent_at, :timestamp
    ActiveRecord::Base.connection.execute("update incoming_messages set last_parsed = null")
  end

  def self.down
    remove_column :incoming_messages, :sent_at
    add_column :incoming_messages, :sent_at, :time
  end
end
