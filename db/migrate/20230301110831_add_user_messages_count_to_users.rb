class AddUserMessagesCountToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :user_messages_count, :integer, default: 0, null: false
  end
end
