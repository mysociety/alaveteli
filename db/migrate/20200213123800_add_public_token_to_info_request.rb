class AddPublicTokenToInfoRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :info_requests, :public_token, :string
  end
end
