class AddInfoRequestIdAndCreatedAtIndexToInfoRequestEvents <
    ActiveRecord::Migration[8.0]
  # Built concurrently, as the table is too large to lock for writes.
  disable_ddl_transaction!

  def change
    add_index :info_request_events, [:info_request_id, :created_at],
              algorithm: :concurrently
  end
end
