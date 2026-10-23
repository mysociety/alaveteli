##
# Job to refresh a record's search documents in the PostgreSQL search index.
#
# Example:
#   Search::ReindexJob.perform_later(InfoRequest.first)
#
class Search::ReindexJob < ApplicationJob
  queue_as :default

  def perform(record)
    record.reindex
  end
end
