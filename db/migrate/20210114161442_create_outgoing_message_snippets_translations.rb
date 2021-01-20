class CreateOutgoingMessageSnippetsTranslations < ActiveRecord::Migration[5.2]
  def change
    OutgoingMessage::Snippet.create_translation_table!(
      name: :string,
      body: :text
    )
  end
end
