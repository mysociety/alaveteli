class AddProminenceReasonToInfoRequest < ActiveRecord::Migration[6.1]
  def change
    add_column :info_requests, :prominence_reason, :text
  end
end
