class AddDatasetPublicColumnsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :dataset_public_columns, :jsonb
  end
end
