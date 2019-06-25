# -*- encoding : utf-8 -*-
class AddEmailTokenToPostRedirects < ActiveRecord::Migration[4.2] # 1.2
  def self.up
    add_column :post_redirects, :email_token, :text
  end

  def self.down
    remove_column :post_redirects, :email_token
  end
end
