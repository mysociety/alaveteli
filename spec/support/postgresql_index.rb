# Rebuild the PostgreSQL search index (the +search_documents+ table) from the
# current fixtures, for specs tagged `:postgresql`.
def rebuild_postgresql_index(models = [PublicBody, User])
  SearchDocument.delete_all
  models.each(&:reindex_all)
end

RSpec.configure do |config|
  config.before(:each, postgresql: true) do
    rebuild_postgresql_index
  end
end
