# -*- encoding : utf-8 -*-
class AddBanUser < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.1
  def self.up
    add_column :users, :ban_text, :text, :null => false, :default => ""
  end

  def self.down
    remove_column :users, :ban_text
  end
end
