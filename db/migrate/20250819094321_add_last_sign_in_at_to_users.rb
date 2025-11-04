class AddLastSignInAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_sign_in_at, :timestamp
  end
end
