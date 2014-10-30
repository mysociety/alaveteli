class ChangeDefaultValueOfInfoRequestProminence < ActiveRecord::Migration
  def change
    change_column_default :info_requests, :prominence, "requester_only"
  end
end
