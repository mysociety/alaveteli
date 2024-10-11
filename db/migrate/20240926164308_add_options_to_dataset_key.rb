class AddOptionsToDatasetKey < ActiveRecord::Migration[7.0]
  def change
    add_column :dataset_keys, :options, :jsonb, default: {}
  end
end
