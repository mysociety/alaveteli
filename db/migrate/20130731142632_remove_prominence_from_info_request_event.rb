# -*- encoding : utf-8 -*-
class RemoveProminenceFromInfoRequestEvent < ActiveRecord::Migration
  def up
    remove_column :info_request_events, :prominence
  end

  def down
    add_column :info_request_events, :prominence, :string, :null => false, :default => 'normal'
  end
end
