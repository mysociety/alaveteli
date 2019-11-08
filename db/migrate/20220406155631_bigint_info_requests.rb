class BigintInfoRequests < ActiveRecord::Migration[6.1]
  def up
    change_column :info_requests, :info_request_batch_id, :bigint
    change_column :info_requests, :last_event_forming_initial_request_id, :bigint
    change_column :info_requests, :public_body_id, :bigint
    change_column :info_requests, :user_id, :bigint
    change_column :info_requests, :id, :bigint
  end

  def down
    change_column :info_requests, :id, :integer
    change_column :info_requests, :user_id, :integer
    change_column :info_requests, :public_body_id, :integer
    change_column :info_requests, :last_event_forming_initial_request_id, :integer
    change_column :info_requests, :info_request_batch_id, :integer
  end
end
