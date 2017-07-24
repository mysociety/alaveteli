# -*- encoding: utf-8 -*-
class AddExpiringNotificationAt < ActiveRecord::Migration
  def change
    add_column :embargoes, :expiring_notification_at, :datetime
  end
end
