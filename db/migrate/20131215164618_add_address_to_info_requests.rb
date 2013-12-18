class AddAddressToInfoRequests < ActiveRecord::Migration
  def change
    add_column :info_requests, :address, :string
  end
end
