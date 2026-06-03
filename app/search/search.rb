##
# Unified search interface providing backend-agnostic querying, indexing,
# and context-based search operations.
#
# This file is ignored by Zeitwerk and required manually via an initializer
# because it reopens the Search module rather than defining Search::Search.
#
# @example Perform a search
#   Search.search('freedom of information', models: [InfoRequestEvent])
#
# @example Typeahead search
#   Search.typeahead('geraldine', model: PublicBody)
#
# @example Context-based search
#   Search.context(info_request: request).similar_requests
#
module Search
  def self.backend
    @backend ||= Adapters::Xapian::Adapter.new
  end

  def self.backend=(backend)
    @backend = backend
  end

  def self.context(info_request: nil)
    Search::Context::InfoRequest.new(info_request) if info_request
  end

  # Direct search - returns a searchable object
  def self.search(query, models:, **options)
    backend.search(query, models: models, **options)
  end

  # Typeahead search - returns a searchable object
  def self.typeahead(query, model:, **options)
    backend.typeahead(query, model: model, **options)
  end

  # Find records similar to the given one - returns a searchable object
  def self.similar(record)
    backend.similar(record)
  end

  # Queue a record for a later search index update
  def self.reindex_later(record)
    backend.reindex_later(record)
  end

  # Index job queue count for health monitoring
  def self.queued_jobs_count
    backend.queued_jobs_count
  end
end
