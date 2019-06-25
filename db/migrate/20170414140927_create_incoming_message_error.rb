# -*- encoding : utf-8 -*-
class CreateIncomingMessageError < ActiveRecord::Migration[4.2] # 4.1
  def change
    create_table :incoming_message_errors do |t|
      t.timestamps null: false
      t.string :unique_id, null: false
      t.datetime :retry_at
      t.text :backtrace
    end

    add_index :incoming_message_errors, :unique_id
  end
end
