# -*- encoding : utf-8 -*-
class AddDescribeStatusHistory < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_request_events, :described_state, :string
    remove_column :info_requests, :described_last_incoming_message_id
  end

  def self.down
    remove_column :info_request_events, :described_state
    add_column :info_requests, :described_last_incoming_message_id, :integer
  end
end
