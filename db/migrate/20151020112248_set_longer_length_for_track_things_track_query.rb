# -*- encoding : utf-8 -*-
class SetLongerLengthForTrackThingsTrackQuery < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def up
    change_column :track_things, :track_query, :string, :limit => 500
  end

  def down
    change_column :track_things, :track_query, :string, :limit => 255
  end
end
