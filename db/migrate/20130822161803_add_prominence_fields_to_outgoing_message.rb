# -*- encoding : utf-8 -*-
class AddProminenceFieldsToOutgoingMessage < ActiveRecord::Migration
  def change
    add_column :outgoing_messages, :prominence, :string, :null => false, :default => 'normal'
    add_column :outgoing_messages, :prominence_reason, :text
  end
end
