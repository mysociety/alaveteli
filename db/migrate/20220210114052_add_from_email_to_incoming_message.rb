class AddFromEmailToIncomingMessage < ActiveRecord::Migration[6.1]
  def change
    add_column :incoming_messages, :from_email, :text
  end
end
