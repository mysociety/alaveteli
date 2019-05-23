# -*- encoding: utf-8 -*-
class AddExpiringNotificationAt < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 4.1
  def up
    unless column_exists?(:embargoes, :expiring_notification_at)
      add_column :embargoes, :expiring_notification_at, :datetime
    end
  end

  def down
    if column_exists?(:embargoes, :expiring_notification_at)
      remove_column :embargoes, :expiring_notification_at
    end
  end

  private

  def column_exists?(table, column)
    if table_exists?(table)
      connection.column_exists?(table, column)
    end
  end

  def table_exists?(table)
    connection.table_exists?(table)
  end
end
