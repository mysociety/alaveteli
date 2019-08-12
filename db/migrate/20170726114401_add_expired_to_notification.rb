# -*- encoding : utf-8 -*-
class AddExpiredToNotification < ActiveRecord::Migration[4.2] # 4.1
  def change
    add_column :notifications, :expired, :boolean, default: false
  end
end
