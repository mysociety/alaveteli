# -*- encoding : utf-8 -*-
class RemoveCharityNumber < ActiveRecord::Migration
  def self.up
    remove_column :public_bodies, :charity_number
  end

  def self.down
    raise "No reverse migration"
  end
end
