# -*- encoding : utf-8 -*-
class AddDisplayOrderToCategoriesAndHeadings < ActiveRecord::Migration
  def up
    add_column :public_body_categories_public_body_headings, :category_display_order, :integer
    rename_table :public_body_categories_public_body_headings, :public_body_category_links
    add_column :public_body_category_links, :id, :primary_key
    add_index :public_body_category_links, [:public_body_category_id, :public_body_heading_id], :name => "index_public_body_category_links_on_join_ids", :primary => true
  end

  def down
    remove_index :public_body_category_links, :name => "index_public_body_category_links_on_join_ids"
    remove_column :public_body_category_links, :category_display_order
    remove_column :public_body_category_links, :id
    rename_table :public_body_category_links, :public_body_categories_public_body_headings
  end
end
