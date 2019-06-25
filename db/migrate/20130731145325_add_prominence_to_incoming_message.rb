# -*- encoding : utf-8 -*-
class AddProminenceToIncomingMessage < ActiveRecord::Migration[4.2] # 3.1
  def change
    add_column :incoming_messages, :prominence, :string, :null => false, :default => 'normal'
  end
end
