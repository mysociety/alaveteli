# -*- encoding: utf-8 -*-
class AddLastEventTimeToInfoRequest < ActiveRecord::Migration[4.2] # 4.1
  def change
    add_column :info_requests, :last_event_time, :datetime
  end
end
