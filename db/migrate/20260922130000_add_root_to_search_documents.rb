class AddRootToSearchDocuments < ActiveRecord::Migration[8.0]
  def up
    add_reference :search_documents, :root, polymorphic: true, index: false

    execute <<~SQL
      UPDATE search_documents
      SET root_type = searchable_type, root_id = searchable_id
      WHERE searchable_type IN ('InfoRequest', 'PublicBody', 'User')
    SQL

    execute <<~SQL
      UPDATE search_documents AS documents
      SET root_type = 'InfoRequest', root_id = messages.info_request_id
      FROM outgoing_messages AS messages
      WHERE documents.searchable_type = 'OutgoingMessage'
        AND documents.searchable_id = messages.id
    SQL
  end

  def down
    remove_reference :search_documents, :root, polymorphic: true, index: false
  end
end
