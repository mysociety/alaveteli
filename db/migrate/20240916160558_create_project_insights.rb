class CreateProjectInsights < ActiveRecord::Migration[7.0]
  def change
    create_table :project_insights do |t|
      t.references :info_request, foreign_key: true
      t.references :project, foreign_key: true
      t.jsonb :output

      t.timestamps
    end
  end
end
