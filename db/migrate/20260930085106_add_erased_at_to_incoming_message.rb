class AddErasedAtToIncomingMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :incoming_messages, :erased_at, :timestamp
  end
end
