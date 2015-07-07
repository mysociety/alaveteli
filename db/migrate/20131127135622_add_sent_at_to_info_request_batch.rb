# -*- encoding : utf-8 -*-
class AddSentAtToInfoRequestBatch < ActiveRecord::Migration
  def change
      add_column :info_request_batches, :sent_at, :datetime
  end
end
