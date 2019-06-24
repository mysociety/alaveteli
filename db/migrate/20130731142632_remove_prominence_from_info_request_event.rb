# -*- encoding : utf-8 -*-
class RemoveProminenceFromInfoRequestEvent <  ActiveRecord::Migration[4.2] # 3.1
  def up
    remove_column :info_request_events, :prominence
  end

  def down
    add_column :info_request_events, :prominence, :string, :null => false, :default => 'normal'
  end
end
