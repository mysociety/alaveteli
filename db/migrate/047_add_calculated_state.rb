# -*- encoding : utf-8 -*-
class AddCalculatedState < ActiveRecord::Migration
  def self.up
    add_column :info_request_events, :calculated_state, :string, :default => nil
  end

  def self.down
    remove_column :info_request_events, :calculated_state
  end
end
