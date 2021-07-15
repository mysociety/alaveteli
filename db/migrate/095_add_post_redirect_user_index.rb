class AddPostRedirectUserIndex < ActiveRecord::Migration[4.2] # 2.3
  # This index is for admin interface

  def self.up
    add_index :post_redirects, :user_id
  end

  def self.down
    remove_index :post_redirects, :user_id
  end
end
