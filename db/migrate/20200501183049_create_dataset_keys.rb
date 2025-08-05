class CreateDatasetKeys < ActiveRecord::Migration[5.1]
  def change
    create_table :dataset_keys do |t|
      t.references :dataset_key_set, foreign_key: true
      t.string :title
      t.string :format
      t.integer :order

      t.timestamps
    end
  end
end
