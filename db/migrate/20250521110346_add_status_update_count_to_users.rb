class AddStatusUpdateCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status_update_count, :integer, default: 0, null: false
  end
end
