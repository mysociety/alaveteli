# -*- encoding : utf-8 -*-
class AddIndexToInfoRequestEvents < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def change
    add_index :info_request_events, :event_type
  end
end
