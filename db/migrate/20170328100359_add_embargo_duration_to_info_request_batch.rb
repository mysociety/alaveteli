class AddEmbargoDurationToInfoRequestBatch < ActiveRecord::Migration
  def change
    add_column :info_request_batches, :embargo_duration, :string
  end
end
