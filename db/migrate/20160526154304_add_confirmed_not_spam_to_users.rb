# -*- encoding : utf-8 -*-
class AddConfirmedNotSpamToUsers <  ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :users, :confirmed_not_spam, :boolean, :default => false, :null => false
  end
end
