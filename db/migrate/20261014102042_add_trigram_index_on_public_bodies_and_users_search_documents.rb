class AddTrigramIndexOnPublicBodiesAndUsersSearchDocuments < ActiveRecord::Migration[8.0]
  def change
    # this is a standard postgres extension,
    # no changes required to the server config
    execute("create extension pg_trgm")

    [:raw_content, :raw_admin_content].each do |col|
      add_index(
        :search_documents_publicbody,
        col,
        using: 'gin',
        opclass: :gin_trgm_ops
      )
    end

    add_index(
      :search_documents_user,
      :raw_admin_content,
      using: 'gin',
      opclass: :gin_trgm_ops
    )
  end
end
