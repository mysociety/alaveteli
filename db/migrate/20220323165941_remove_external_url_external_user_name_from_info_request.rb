class RemoveExternalUrlExternalUserNameFromInfoRequest < ActiveRecord::Migration[6.1]
  def change
    remove_column :info_requests, :external_url
    remove_column :info_requests, :external_user_name
  end
end
