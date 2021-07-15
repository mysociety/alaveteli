class AddRequestCreatedAtAndRequestUpdatedAtToRequestSummary < ActiveRecord::Migration[4.2] # 4.1
  def change
    add_column :request_summaries, :request_created_at, :datetime, null: false, default: Time.now
    add_column :request_summaries, :request_updated_at, :datetime, null: false, default: Time.now
  end
end
