class AddErasedAtToOutgoingMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :outgoing_messages, :erased_at, :timestamp
  end
end
