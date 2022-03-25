class RemoveExternalUrlExternalUserNameFromInfoRequest < ActiveRecord::Migration[6.1]
  def change
    remove_column :info_requests, :external_url, :string, null: true
    remove_column :info_requests, :external_user_name, :string, null: true
  end
end
