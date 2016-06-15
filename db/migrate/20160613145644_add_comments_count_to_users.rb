# -*- encoding : utf-8 -*-
class AddCommentsCountToUsers < ActiveRecord::Migration
  def up
    add_column :users, :comments_count, :integer, :default => 0, :null => false

    Comment.uniq.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :comments)
    end
  end

  def down
    remove_column :users, :comments_count
  end
end
