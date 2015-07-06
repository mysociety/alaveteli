# -*- encoding : utf-8 -*-
class ChangeClassificationSystem < ActiveRecord::Migration
  def self.up
    remove_column :incoming_messages, :contains_information
    remove_column :incoming_messages, :user_classified

    add_column :info_requests, :described_state, :string
    InfoRequest.update_all "described_state = 'waiting_response'"
    change_column :info_requests, :described_state, :string, :null => false

    add_column :info_requests, :awaiting_description, :boolean, :default => false, :null => false
    InfoRequest.update_all "awaiting_description = 't' where (select count(*) from incoming_messages where info_request_id = info_requests.id) > 0"

    add_column :info_requests, :described_last_incoming_message_id, :integer
    InfoRequest.update_all "described_last_incoming_message_id = null"
  end

  def self.down
    add_column :incoming_messages, :contains_information, :boolean
    add_column :incoming_messages, :user_classified, :boolean

    remove_column :info_requests, :described_state
    remove_column :info_requests, :awaiting_description
    remove_column :info_requests, :described_last_incoming_message_id
  end
end
