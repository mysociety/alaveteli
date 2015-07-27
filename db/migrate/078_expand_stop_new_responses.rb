# -*- encoding : utf-8 -*-
class ExpandStopNewResponses < ActiveRecord::Migration
  def self.up
    add_column :info_requests, :allow_new_responses_from, :string
    InfoRequest.update_all "allow_new_responses_from = 'anybody'"
    InfoRequest.update_all "allow_new_responses_from = 'nobody' where stop_new_responses"
    change_column :info_requests, :allow_new_responses_from, :string, :null => false, :default => 'anybody'
    remove_column :info_requests, :stop_new_responses

    add_column :info_requests, :handle_rejected_responses, :string
    InfoRequest.update_all "handle_rejected_responses = 'bounce'"
    change_column :info_requests, :handle_rejected_responses, :string, :null => false, :default => 'bounce'
  end

  def self.down
    raise "No code for reversing this"
  end
end
