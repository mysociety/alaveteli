# -*- encoding : utf-8 -*-
class CreateDraftInfoRequests < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
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
