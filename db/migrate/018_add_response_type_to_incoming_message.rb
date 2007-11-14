class AddResponseTypeToIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :user_classified, :boolean, :default => false
    add_column :incoming_messages, :contains_information, :boolean, :default => false

    create_table :rejection_reasons do |t|
      t.column :incoming_message_id, :integer
      t.column :reason, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    remove_column :incoming_messages, :contains_information
    drop_table :rejection_reasons
  end
end
