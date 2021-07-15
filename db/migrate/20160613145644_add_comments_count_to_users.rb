class AddCommentsCountToUsers < ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :users, :comments_count, :integer, :default => 0, :null => false

    Comment.distinct.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :comments)
    end
  end

  def down
    remove_column :users, :comments_count
  end
end
