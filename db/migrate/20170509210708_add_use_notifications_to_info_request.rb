# -*- encoding : utf-8 -*-
class AddUseNotificationsToInfoRequest < ActiveRecord::Migration[4.2] # 4.1
  def change
    add_column :info_requests, :use_notifications, :boolean
  end
end
