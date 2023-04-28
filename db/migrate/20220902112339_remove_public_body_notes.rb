class RemovePublicBodyNotes < ActiveRecord::Migration[6.1]
  def up
    if PublicBody::Translation.where.not(notes: nil).any?
      raise <<~TXT
        We can't run the RemovePublicBodyNotes database migration.

        We have dectected PublicBody::Translation objects which haven't been
        migrated to the new Note model.

        Please deploy Alaveteli 0.42.0.0 and run the upgrade tasks:
        https://github.com/mysociety/alaveteli/blob/0.42.0.0/doc/CHANGES.md#upgrade-notes

      TXT
    end

    remove_column :public_body_translations, :notes
  end

  def down
    PublicBody.add_translation_fields! notes: :text
  end
end
