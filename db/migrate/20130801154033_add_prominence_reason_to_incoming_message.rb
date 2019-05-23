# -*- encoding : utf-8 -*-
class AddProminenceReasonToIncomingMessage < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.1
  def change
    add_column :incoming_messages, :prominence_reason, :text
  end
end
