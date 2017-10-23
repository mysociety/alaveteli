# -*- encoding: utf-8 -*-
class AddLastEventTimeToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :last_event_time, :datetime
  end
end
