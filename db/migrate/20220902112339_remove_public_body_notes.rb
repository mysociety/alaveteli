class RemovePublicBodyNotes < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        remove_column :public_body_translations, :notes
      end

      dir.down do
        PublicBody.add_translation_fields! notes: :text
      end
    end
  end
end
