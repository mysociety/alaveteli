class AddTimestampsToHolidays < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:holidays, null: true)
  end
end
