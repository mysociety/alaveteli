# -*- encoding : utf-8 -*-
class AddProminenceReasonToIncomingMessage < ActiveRecord::Migration
  def change
    add_column :incoming_messages, :prominence_reason, :text
  end
end
