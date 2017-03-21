# -*- encoding : utf-8 -*-
class EditInfoRequestBatchIndex < ActiveRecord::Migration
  def change
    remove_index :info_request_batches, :column =>  [:user_id, :body, :title]
    add_index :info_request_batches, [:user_id, :title]
  end
end
