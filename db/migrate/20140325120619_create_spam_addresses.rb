# -*- encoding : utf-8 -*-
class CreateSpamAddresses < ActiveRecord::Migration
  def change
    create_table :spam_addresses do |t|
      t.string :email, :null => false

      t.timestamps :null => false
    end
  end
end
