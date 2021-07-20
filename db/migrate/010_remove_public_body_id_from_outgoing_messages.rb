class RemovePublicBodyIdFromOutgoingMessages < ActiveRecord::Migration[4.2] # 1.2
  def self.up
    remove_column :outgoing_messages, :public_body_id
  end

  def self.down
    add_column :outgoing_messages, :public_body_id, :integer
  end
end
