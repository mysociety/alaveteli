class RemoveRedundantSearchDocumentsIndex < ActiveRecord::Migration[8.0]
  def change
    # this drops the corresponding index on each partition
    remove_index(
      :search_documents,
      column: [:searchable_type, :searchable_id],
      name: :index_search_documents_on_searchable
    )
  end
end
