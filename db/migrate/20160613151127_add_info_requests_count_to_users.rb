# -*- encoding : utf-8 -*-
class AddInfoRequestsCountToUsers <  ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :users, :info_requests_count, :integer, :default => 0, :null => false

    InfoRequest.distinct.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :info_requests)
    end
  end

  def down
    remove_column :users, :info_requests_count
  end
end
