# Rebuild the PostgreSQL search index (the +search_documents+ table) from the
# current fixtures, for specs tagged `:postgresql`.
def rebuild_postgresql_index(models = [InfoRequest, PublicBody, User])
  SearchDocument.delete_all
  models.each(&:reindex_all)
end

RSpec.configure do |config|
  config.before(:each, postgresql: true) do
    rebuild_postgresql_index
  end

  config.around(:each, postgresql: true) do |example|
    original = Search.backend
    Search.backend = Search.backend_for(:postgresql)
    example.run
  ensure
    Search.backend = original
  end
end
