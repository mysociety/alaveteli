# -*- encoding : utf-8 -*-
class RemoveContainsInformationDefault < ActiveRecord::Migration[4.2] # 1.2
  def self.up
    change_column :incoming_messages, :contains_information, :boolean, default: nil
    drop_table :rejection_reasons
  end

  def self.down
    change_column :incoming_messages, :contains_information, :boolean, default: false
    create_table :rejection_reasons do |t|
      t.column :incoming_message_id, :integer
      t.column :reason, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end
