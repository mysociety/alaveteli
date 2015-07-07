# -*- encoding : utf-8 -*-
class AddIndexToInfoRequestEvents < ActiveRecord::Migration
  def change
    add_index :info_request_events, :event_type
  end
end
