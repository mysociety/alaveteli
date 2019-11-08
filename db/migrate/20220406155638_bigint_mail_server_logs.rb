class BigintMailServerLogs < ActiveRecord::Migration[6.1]
  def up
    change_column :mail_server_logs, :info_request_id, :bigint
    change_column :mail_server_logs, :mail_server_log_done_id, :bigint
    change_column :mail_server_logs, :id, :bigint
  end

  def down
    change_column :mail_server_logs, :id, :integer
    change_column :mail_server_logs, :mail_server_log_done_id, :integer
    change_column :mail_server_logs, :info_request_id, :integer
  end
end
