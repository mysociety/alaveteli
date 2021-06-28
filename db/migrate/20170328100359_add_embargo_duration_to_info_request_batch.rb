class AddEmbargoDurationToInfoRequestBatch < ActiveRecord::Migration[4.2] # 4.0
  def change
    add_column :info_request_batches, :embargo_duration, :string
  end
end
