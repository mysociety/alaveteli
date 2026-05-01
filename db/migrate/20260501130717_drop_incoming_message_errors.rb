class DropIncomingMessageErrors < ActiveRecord::Migration[8.0]
  def change
    drop_table :incoming_message_errors do |t|
      t.timestamps null: false
      t.string :unique_id, null: false
      t.datetime :retry_at
      t.text :backtrace
      t.index :unique_id
    end
  end
end
