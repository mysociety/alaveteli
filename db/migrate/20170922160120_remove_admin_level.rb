# -*- encoding : utf-8 -*-
class RemoveAdminLevel < ActiveRecord::Migration
  def self.up
    remove_column :users, :admin_level
  end

  def self.down
    add_column :users, :admin_level, :string, :null => false, :default => 'none'
  end
end
