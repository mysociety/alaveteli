class AddDatasetPublicToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :dataset_public, :boolean, default: false
  end
end
