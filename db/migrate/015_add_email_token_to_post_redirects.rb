class AddEmailTokenToPostRedirects < ActiveRecord::Migration
  def self.up
    add_column :post_redirects, :email_token, :text
  end

  def self.down
    remove_column :post_redirects, :email_token
  end
end
