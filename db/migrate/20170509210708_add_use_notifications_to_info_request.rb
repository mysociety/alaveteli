class AddUseNotificationsToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :use_notifications, :boolean
  end
end
