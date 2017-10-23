# -*- encoding : utf-8 -*-
class AddDailySummaryTimeToUser < ActiveRecord::Migration
  def change
    add_column :users, :daily_summary_hour, :integer
    add_column :users, :daily_summary_minute, :integer
  end
end
