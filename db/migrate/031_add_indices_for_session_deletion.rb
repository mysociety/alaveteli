# -*- encoding : utf-8 -*-
class AddIndicesForSessionDeletion <  ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_index :post_redirects, :updated_at
  end

  def self.down
    remove_index :post_redirects, :updated_at
  end
end
