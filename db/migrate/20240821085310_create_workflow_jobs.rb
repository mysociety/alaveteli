class CreateWorkflowJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :workflow_jobs do |t|
      t.string :type
      t.references :resource, polymorphic: true
      t.integer :status
      t.references :parent
      t.jsonb :metadata

      t.timestamps
    end
  end
end
