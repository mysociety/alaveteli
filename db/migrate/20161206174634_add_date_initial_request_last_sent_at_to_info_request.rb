# -*- encoding : utf-8 -*-
class AddDateInitialRequestLastSentAtToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :date_initial_request_last_sent_at, :date
  end
end
