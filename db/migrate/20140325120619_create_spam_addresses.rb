# -*- encoding : utf-8 -*-
class CreateSpamAddresses < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def change
    create_table :spam_addresses do |t|
      t.string :email, :null => false

      t.timestamps :null => false
    end
  end
end
