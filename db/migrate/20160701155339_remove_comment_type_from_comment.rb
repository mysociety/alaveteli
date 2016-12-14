# -*- encoding : utf-8 -*-
class RemoveCommentTypeFromComment < ActiveRecord::Migration
  def up
    remove_column :comments, :comment_type
  end

  def down
    add_column :comments, :comment_type, :string, :null => false, :default => 'request'
  end
end
