class AddTimestampsToProfilePhotos < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:profile_photos, null: true)
  end
end
