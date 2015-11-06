# -*- encoding : utf-8 -*-
class SetLongerLengthForTrackThingsTrackQuery < ActiveRecord::Migration
  def up
    change_column :track_things, :track_query, :string, :limit => 500
  end

  def down
    change_column :track_things, :track_query, :string, :limit => 255
  end
end
