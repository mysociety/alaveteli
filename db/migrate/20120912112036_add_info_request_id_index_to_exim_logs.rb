# -*- encoding : utf-8 -*-
class AddInfoRequestIdIndexToEximLogs < ActiveRecord::Migration
  def self.up
      add_index :exim_logs, :info_request_id
  end

  def self.down
      remove_index :exim_logs, :info_request_id
  end
end
