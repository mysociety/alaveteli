# -*- encoding : utf-8 -*-
require 'digest/sha1'

class AddUserNoLimit < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_column :users, :no_limit, :boolean, :default => false, :null => false
  end
  def self.down
    remove_column :users, :no_limit
  end
end
