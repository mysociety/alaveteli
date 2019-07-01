# -*- encoding : utf-8 -*-
class CreateDraftInfoRequestBatches < ActiveRecord::Migration[4.2] # 4.0
  def change
    create_table :draft_info_request_batches do |t|
      t.string :title
      t.text :body
      t.references :user

      t.timestamps :null => false
    end
    add_index :draft_info_request_batches, :user_id
  end
end
