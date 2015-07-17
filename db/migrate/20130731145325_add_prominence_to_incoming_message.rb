# -*- encoding : utf-8 -*-
class AddProminenceToIncomingMessage < ActiveRecord::Migration
  def change
    add_column :incoming_messages, :prominence, :string, :null => false, :default => 'normal'
  end
end
