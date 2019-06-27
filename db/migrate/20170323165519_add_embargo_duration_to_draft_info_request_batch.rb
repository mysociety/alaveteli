# -*- encoding : utf-8 -*-
class AddEmbargoDurationToDraftInfoRequestBatch < ActiveRecord::Migration[4.2] # 4.0
  def change
    add_column :draft_info_request_batches, :embargo_duration, :string
  end
end
