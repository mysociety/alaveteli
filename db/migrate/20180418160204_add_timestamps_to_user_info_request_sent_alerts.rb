# -*- encoding : utf-8 -*-
class AddTimestampsToUserInfoRequestSentAlerts < ActiveRecord::Migration
  def change
    add_timestamps(:user_info_request_sent_alerts)
  end
end
