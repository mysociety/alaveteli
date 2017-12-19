class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end

    create_table :announcement_translations do |t|
      t.references :announcement, index: true, foreign_key: true, null: false
      t.string :locale
      t.string :title
      t.text :content

      t.timestamps null: false
    end
  end
end
