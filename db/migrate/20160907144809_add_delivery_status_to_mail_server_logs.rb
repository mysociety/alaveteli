# -*- encoding : utf-8 -*-
class AddDeliveryStatusToMailServerLogs < ActiveRecord::Migration
  def up
    add_column :mail_server_logs, :delivery_status, :string
  end

  def down
    remove_column :mail_server_logs, :delivery_status
  end
end
