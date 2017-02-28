class CreateDraftInfoRequests < ActiveRecord::Migration
  def change
    create_table :draft_info_requests do |t|
      t.string :title
      t.integer :user_id
      t.integer :public_body_id
      t.text :body
      t.string :embargo_duration

      t.timestamps null: false
    end
  end
end
