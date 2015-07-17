# -*- encoding : utf-8 -*-
class CreatePublicBodyHeadingsAndCategories < ActiveRecord::Migration
  def up
    create_table :public_body_headings, :force => true do |t|
      t.string :locale
      t.text :name, :null => false
      t.integer :display_order
    end

    create_table :public_body_categories, :force => true do |t|
      t.string :locale
      t.text :title, :null => false
      t.text :category_tag, :null => false
      t.text :description, :null => false
    end

    create_table :public_body_categories_public_body_headings, :id => false do |t|
      t.integer :public_body_category_id, :null => false
      t.integer :public_body_heading_id, :null => false
    end
  end

  def down
    drop_table :public_body_categories
    drop_table :public_body_headings
    drop_table :public_body_categories_public_body_headings
  end
end
