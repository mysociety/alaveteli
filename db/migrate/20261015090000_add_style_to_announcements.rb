class AddStyleToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :style, :string, default: 'default', null: false
  end
end
