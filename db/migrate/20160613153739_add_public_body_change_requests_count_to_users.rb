# -*- encoding : utf-8 -*-
class AddPublicBodyChangeRequestsCountToUsers <  ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :users, :public_body_change_requests_count, :integer, :default => 0, :null => false

    PublicBodyChangeRequest.distinct.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :public_body_change_requests)
    end
  end

  def down
    remove_column :users, :public_body_change_requests_count
  end
end
