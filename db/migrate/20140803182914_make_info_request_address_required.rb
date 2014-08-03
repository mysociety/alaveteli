class MakeInfoRequestAddressRequired < ActiveRecord::Migration
  def change
    change_column :info_requests, :address, :string, :null => false
  end
end
