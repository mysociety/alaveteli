# -*- encoding : utf-8 -*-
class OutgoingMessageLastSentAt < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    rename_column(:outgoing_messages, :sent_at, :last_sent_at)
  end

  def self.down
    rename_column(:outgoing_messages, :last_sent_at, :sent_at)
  end
end
