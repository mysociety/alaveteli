# -*- encoding : utf-8 -*-
class AddConfirmedNotSpamToUsers < ActiveRecord::Migration
  def change
    add_column :users, :confirmed_not_spam, :boolean, :default => false, :null => false
  end
end
