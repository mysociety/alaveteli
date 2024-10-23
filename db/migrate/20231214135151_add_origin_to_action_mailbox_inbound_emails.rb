class AddOriginToActionMailboxInboundEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :action_mailbox_inbound_emails, :origin, :string
  end
end
