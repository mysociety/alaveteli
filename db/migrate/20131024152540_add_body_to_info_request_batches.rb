class AddBodyToInfoRequestBatches < ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :info_request_batches, :body, :text
    add_index :info_request_batches, [:user_id, :body, :title]
  end

  def down
    remove_column :info_request_batches, :body
  end

end
