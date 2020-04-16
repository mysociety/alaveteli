class CreateProjectResources < ActiveRecord::Migration[5.1]
  def change
    create_table :project_resources do |t|
      t.references :project, foreign_key: true
      t.references :resource, polymorphic: true

      t.timestamps
    end
  end
end
