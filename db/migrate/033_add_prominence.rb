# -*- encoding : utf-8 -*-
class AddProminence < ActiveRecord::Migration
  def self.up
    add_column :info_requests, :prominence, :string, :null => false, :default => 'normal'
  end

  def self.down
    remove_column :info_requests, :prominence
  end
end
