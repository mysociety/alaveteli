class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :send_daily_summary, :boolean, default: true, null: false
    add_column :users, :send_immediate_request_alerts, :boolean, default: true, null: false
  end
end
