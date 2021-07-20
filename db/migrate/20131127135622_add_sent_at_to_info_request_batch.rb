class AddSentAtToInfoRequestBatch < ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :info_request_batches, :sent_at, :datetime
  end
end
