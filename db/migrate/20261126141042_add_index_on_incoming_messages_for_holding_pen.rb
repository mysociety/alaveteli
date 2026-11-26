class AddIndexOnIncomingMessagesForHoldingPen < ActiveRecord::Migration[8.0]
  def change
    add_index(
      :incoming_messages,
      :subject,
      using: 'btree'
    )
  end
end
