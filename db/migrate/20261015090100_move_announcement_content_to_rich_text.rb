class MoveAnnouncementContentToRichText < ActiveRecord::Migration[8.0]
  RECORD_TYPE = 'Announcement::Translation'.freeze

  def up
    execute <<~SQL
      INSERT INTO action_text_rich_texts
        (name, body, record_type, record_id, created_at, updated_at)
      SELECT 'rich_body', content, '#{RECORD_TYPE}', id, NOW(), NOW()
      FROM announcement_translations
      WHERE content IS NOT NULL AND content <> ''
    SQL

    remove_column :announcement_translations, :content
  end

  # Lossy only in that rich text formatting is stored as HTML in content
  def down
    add_column :announcement_translations, :content, :text

    execute <<~SQL
      UPDATE announcement_translations
      SET content = action_text_rich_texts.body
      FROM action_text_rich_texts
      WHERE action_text_rich_texts.record_type = '#{RECORD_TYPE}'
        AND action_text_rich_texts.record_id = announcement_translations.id
        AND action_text_rich_texts.name = 'rich_body'
    SQL

    execute <<~SQL
      DELETE FROM action_text_rich_texts
      WHERE record_type = '#{RECORD_TYPE}' AND name = 'rich_body'
    SQL
  end
end
