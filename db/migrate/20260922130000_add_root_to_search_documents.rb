class AddRootToSearchDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :search_documents, :root, polymorphic: true, index: false
  end
end
