class AddReceiveUserMessagesToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :receive_user_messages, :boolean,
               default: true, null: false
  end
end
