# -*- encoding : utf-8 -*-
class RemoveCommentTypeFromComment < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def up
    remove_column :comments, :comment_type
  end

  def down
    add_column :comments, :comment_type, :string, :null => false, :default => 'request'
  end
end
