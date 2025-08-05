class CreateDatasetValues < ActiveRecord::Migration[5.1]
  def change
    create_table :dataset_values do |t|
      t.references :dataset_value_set, foreign_key: true
      t.references :dataset_key, foreign_key: true
      t.string :value
      t.string :notes

      t.timestamps
    end
  end
end
