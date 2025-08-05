class CreateCitations < ActiveRecord::Migration[5.1]
  def change
    create_table :citations do |t|
      t.references :user, foreign_key: true
      t.references :citable, polymorphic: true
      t.string :source_url
      t.string :type

      t.timestamps
    end
  end
end
