class AddDeliveryStatusToMailServerLogs < ActiveRecord::Migration
  def up
    add_column :mail_server_logs, :delivery_status, :string
    MailServerLog.where(:delivery_status => nil).find_each do |mail_log|
      mail_log.update_attributes(:delivery_status => mail_log.delivery_status)
    end
  end

  def down
    remove_column :mail_server_logs, :delivery_status
  end
end
