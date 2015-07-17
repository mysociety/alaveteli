# -*- encoding : utf-8 -*-
class StopNewResponses < ActiveRecord::Migration
  def self.up
    add_column :info_requests, :stop_new_responses, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :info_requests, :stop_new_responses
  end
end
