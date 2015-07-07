# -*- encoding : utf-8 -*-
class AddInfoRequestEventIndexToUserInfoRequestSentAlerts < ActiveRecord::Migration
  def self.up
      add_index :user_info_request_sent_alerts, :info_request_event_id
  end

  def self.down
      remove_index :user_info_request_sent_alerts, :info_request_event_id
  end
end
