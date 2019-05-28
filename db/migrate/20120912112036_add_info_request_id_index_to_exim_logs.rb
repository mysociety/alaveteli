# -*- encoding : utf-8 -*-
class AddInfoRequestIdIndexToEximLogs <  ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :exim_logs, :info_request_id
  end

  def self.down
    remove_index :exim_logs, :info_request_id
  end
end
