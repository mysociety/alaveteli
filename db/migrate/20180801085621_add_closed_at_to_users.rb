class AddClosedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :closed_at, :timestamp
  end
end
