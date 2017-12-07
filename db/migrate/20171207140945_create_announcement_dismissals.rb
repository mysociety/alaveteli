class CreateAnnouncementDismissals < ActiveRecord::Migration
  def change
    create_table :announcement_dismissals, force: true do |t|
      t.references :announcement, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
