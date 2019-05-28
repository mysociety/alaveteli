# -*- encoding : utf-8 -*-
class AddAdminUsers <  ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :users, :admin_level, :string, :null => false, :default => 'none'
  end

  def self.down
    remove_column :users, :admin_level
  end
end
