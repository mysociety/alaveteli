class CreateDatasetValueSets < ActiveRecord::Migration[5.1]
  def change
    create_table :dataset_value_sets do |t|
      t.references :resource, polymorphic: true
      t.references :dataset_key_set, foreign_key: true

      t.timestamps
    end
  end
end
