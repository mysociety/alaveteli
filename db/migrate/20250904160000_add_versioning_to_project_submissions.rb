class AddVersioningToProjectSubmissions < ActiveRecord::Migration[5.1]
  def change
    add_column :project_submissions, :parent_id, :bigint
    add_column :project_submissions, :current, :boolean, default: true, null: false

    add_foreign_key :project_submissions, :project_submissions, column: :parent_id

    add_index :project_submissions, :parent_id
    add_index :project_submissions, :current
  end
end
