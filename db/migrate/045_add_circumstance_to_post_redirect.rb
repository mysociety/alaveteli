# -*- encoding : utf-8 -*-
class AddCircumstanceToPostRedirect < ActiveRecord::Migration
  def self.up
    add_column :post_redirects, :circumstance, :text, :default => "normal"
    PostRedirect.update_all "circumstance = 'normal'"
    change_column :post_redirects, :circumstance, :text, :default => "normal", :null => false
  end

  def self.down
    remove_column :post_redirects, :circumstance
  end
end
