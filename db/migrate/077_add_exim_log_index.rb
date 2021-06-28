class AddEximLogIndex < ActiveRecord::Migration[4.2] # 2.1
  def self.up
    add_index :exim_logs, :exim_log_done_id
  end

  def self.down
    remove_index :exim_logs, :exim_log_done_id
  end
end
