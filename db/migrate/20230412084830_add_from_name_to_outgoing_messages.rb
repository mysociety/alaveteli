class AddFromNameToOutgoingMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :outgoing_messages, :from_name, :text
  end
end
