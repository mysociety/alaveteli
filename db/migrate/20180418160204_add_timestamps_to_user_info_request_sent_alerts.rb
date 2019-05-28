# -*- encoding : utf-8 -*-
class AddTimestampsToUserInfoRequestSentAlerts <  ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:user_info_request_sent_alerts, null: true)
  end
end
