# -*- encoding : utf-8 -*-
class AddPostRedirectUserIndex < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  # This index is for admin interface

  def self.up
    add_index :post_redirects, :user_id
  end

  def self.down
    remove_index :post_redirects, :user_id
  end
end
