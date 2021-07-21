class CreateAlaveteliProRequestSummaries < ActiveRecord::Migration[4.2] # 4.1
  def change
    create_table :request_summaries do |t|
      t.text :title
      t.text :body
      t.text :public_body_names
      t.references :summarisable, :polymorphic => true

      t.timestamps :null => false
    end
  end
end
