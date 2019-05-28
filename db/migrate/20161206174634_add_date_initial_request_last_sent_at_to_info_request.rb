# -*- encoding : utf-8 -*-
class AddDateInitialRequestLastSentAtToInfoRequest <  ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :info_requests, :date_initial_request_last_sent_at, :date
  end
end
