class AddEmbargoDurationToDraftInfoRequestBatch < ActiveRecord::Migration
  def change
    add_column :draft_info_request_batches, :embargo_duration, :string
  end
end
