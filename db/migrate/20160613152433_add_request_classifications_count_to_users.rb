# -*- encoding : utf-8 -*-
class AddRequestClassificationsCountToUsers < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :users, :request_classifications_count, :integer, :default => 0, :null => false

    RequestClassification.distinct.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :request_classifications)
    end
  end

  def down
    remove_column :users, :request_classifications_count
  end
end
