class AddInfoRequestBatchesCountToUsers < ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :users, :info_request_batches_count, :integer, :default => 0, :null => false

    InfoRequestBatch.distinct.pluck(:user_id).compact.each do |user_id|
      User.reset_counters(user_id, :info_request_batches)
    end
  end

  def down
    remove_column :users, :info_request_batches_count
  end
end
