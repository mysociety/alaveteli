class CreateNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :notes do |t|
      t.references :notable, polymorphic: true
      t.string :notable_tag
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Note.create_translation_table!(body: :text)
      end

      dir.down do
        Note.drop_translation_table!
      end
    end
  end
end
