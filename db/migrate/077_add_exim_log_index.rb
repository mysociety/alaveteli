# -*- encoding : utf-8 -*-
class AddEximLogIndex < ActiveRecord::Migration
  def self.up
    add_index :exim_logs, :exim_log_done_id
  end

  def self.down
    remove_index :exim_logs, :exim_log_done_id
  end
end
