class CreateCategoryRelationships < ActiveRecord::Migration[7.0]
  def change
    create_table :category_relationships do |t|
      t.integer :parent_id, null: false
      t.integer :child_id, null: false
      t.integer :position

      t.timestamps
    end

    add_index :category_relationships, :parent_id
    add_index :category_relationships, :child_id
    add_index :category_relationships, [:parent_id, :child_id], unique: true
  end
end
