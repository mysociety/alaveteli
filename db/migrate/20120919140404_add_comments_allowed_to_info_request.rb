# -*- encoding : utf-8 -*-
class AddCommentsAllowedToInfoRequest < ActiveRecord::Migration
  def self.up
    add_column :info_requests, :comments_allowed, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :info_requests, :comments_allowed
  end
end
