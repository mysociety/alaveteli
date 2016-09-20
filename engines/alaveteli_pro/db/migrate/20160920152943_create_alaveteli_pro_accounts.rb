class CreateAlaveteliProAccounts < ActiveRecord::Migration
  def change
    create_table :alaveteli_pro_accounts do |t|
      t.integer :user_id
      t.timestamps
    end
    add_index :alaveteli_pro_accounts, :user_id
  end
end
