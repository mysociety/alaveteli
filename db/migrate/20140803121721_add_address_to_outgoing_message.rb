class AddAddressToOutgoingMessage < ActiveRecord::Migration
  def change
    add_column :outgoing_messages, :address, :string
  end
end
