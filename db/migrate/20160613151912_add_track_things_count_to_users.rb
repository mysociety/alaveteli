# -*- encoding : utf-8 -*-
class AddTrackThingsCountToUsers < ActiveRecord::Migration
  def up
    add_column :users, :track_things_count, :integer, :default => 0, :null => false

    TrackThing.uniq.pluck(:tracking_user_id).compact.each do |user_id|
      User.reset_counters(user_id, :track_things)
    end
  end

  def down
    remove_column :users, :track_things_count
  end
end
