# -*- encoding : utf-8 -*-
class AddTimestampsToProfilePhotos < ActiveRecord::Migration
  def change
    add_timestamps(:profile_photos)
  end
end
