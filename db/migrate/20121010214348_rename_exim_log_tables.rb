# -*- encoding : utf-8 -*-
class RenameEximLogTables < ActiveRecord::Migration
  def self.up
    rename_table :exim_logs, :mail_server_logs
    rename_table :exim_log_dones, :mail_server_log_dones
    rename_column :mail_server_logs, :exim_log_done_id, :mail_server_log_done_id
  end

  def self.down
    rename_table :mail_server_logs, :exim_logs
    rename_table :mail_server_log_dones, :exim_log_dones
    rename_column :exim_logs, :mail_server_log_done_id, :exim_log_done_id
  end
end
