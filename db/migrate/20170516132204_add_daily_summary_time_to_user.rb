class AddDailySummaryTimeToUser < ActiveRecord::Migration[4.2] # 4.1
  def change
    add_column :users, :daily_summary_hour, :integer
    add_column :users, :daily_summary_minute, :integer
  end
end
