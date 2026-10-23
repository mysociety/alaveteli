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

  # Records are indexed by a job after they are saved. Specs tagged
  # `:reindex_inline` run that job straight away, so they can search for
  # records they have just created.
  config.around(:each, reindex_inline: true) do |example|
    perform_enqueued_jobs(only: Search::ReindexJob) { example.run }
  end
end
