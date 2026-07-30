class ChangeSearchDocumentsRawColumnsToJsonb < ActiveRecord::Migration[8.0]
  def up
    remove_column(:search_documents, :raw_content)
    remove_column(:search_documents, :raw_admin_content)

    add_column(:search_documents, :raw_content, :jsonb)
    add_column(:search_documents, :raw_admin_content, :jsonb)
  end

  def down
    remove_column(:search_documents, :raw_content)
    remove_column(:search_documents, :raw_admin_content)

    add_column(:search_documents, :raw_content, :text)
    add_column(:search_documents, :raw_admin_content, :text)
  end
end
