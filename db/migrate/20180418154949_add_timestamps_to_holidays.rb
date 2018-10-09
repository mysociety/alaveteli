# -*- encoding : utf-8 -*-
class AddTimestampsToHolidays < ActiveRecord::Migration
  def change
    add_timestamps(:holidays)
  end
end
