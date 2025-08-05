class CreateDatasetKeySets < ActiveRecord::Migration[5.1]
  def change
    create_table :dataset_key_sets do |t|
      t.references :resource, polymorphic: true

      t.timestamps
    end
  end
end
