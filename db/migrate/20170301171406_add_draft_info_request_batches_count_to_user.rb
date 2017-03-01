class AddDraftInfoRequestBatchesCountToUser < ActiveRecord::Migration
  def change
    add_column :users,
               :draft_info_request_batches_count,
               :integer,
               default: 0,
               null: false
  end
end
