# -*- encoding : utf-8 -*-
class AddTimestampsToProfilePhotos < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:profile_photos, null: true)
  end
end
