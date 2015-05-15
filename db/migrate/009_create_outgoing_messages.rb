# -*- encoding : utf-8 -*-
class CreateOutgoingMessages < ActiveRecord::Migration
  def self.up
    create_table :outgoing_messages do |t|
      t.column :info_request_id, :integer

      t.column :body, :text
      t.column :status, :string

      t.column :public_body_id, :integer
      t.column :message_type, :string

      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :outgoing_messages
  end
end
