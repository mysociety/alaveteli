# -*- encoding : utf-8 -*-
class AddAboutMe < ActiveRecord::Migration
  def self.up
    add_column :users, :about_me, :text, :null => false, :default => ""
  end

  def self.down
    raise "No reverse migration"
    #remove_column :users, :about_me
  end
end
