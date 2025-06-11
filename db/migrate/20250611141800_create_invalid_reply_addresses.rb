class CreateInvalidReplyAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :invalid_reply_addresses do |t|
      t.string :email, null: false

      t.timestamps null: false
    end
  end
end