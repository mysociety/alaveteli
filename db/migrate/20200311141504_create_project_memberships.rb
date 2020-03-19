class CreateProjectMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :project_memberships do |t|
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.references :role, foreign_key: true

      t.timestamps
    end
  end
end
