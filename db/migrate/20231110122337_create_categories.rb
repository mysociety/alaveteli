class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :category_tag

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Category.create_translation_table! title: :string, description: :string
      end

      dir.down do
        Category.drop_translation_table!
      end
    end
  end
end
