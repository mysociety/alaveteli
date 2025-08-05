# -*- encoding : utf-8 -*-
class RemoveCharityNumber < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    remove_column :public_bodies, :charity_number
  end

  def self.down
    raise "No reverse migration"
  end
end
