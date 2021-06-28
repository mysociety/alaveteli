class CreateDraftInfoRequestBatchesPublicBodiesTable < ActiveRecord::Migration[4.2] # 4.0
  def change
    create_table :draft_info_request_batches_public_bodies,
                 :id => false do |t|
      t.references :draft_info_request_batch
      t.references :public_body
    end

    add_index :draft_info_request_batches_public_bodies,
              [:draft_info_request_batch_id, :public_body_id],
              name: 'index_draft_batch_body_and_draft'
    add_index :draft_info_request_batches_public_bodies,
              :public_body_id,
              name: 'index_draft_batch_body'
  end
end
