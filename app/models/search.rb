##
# Unified search interface providing backend-agnostic querying, indexing,
# and context-based search operations.
#
# This file defines the Search module and its facade methods. Zeitwerk
# autoloads it as the namespace for the classes under app/models/search.
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

  def self.backends
    @backends ||= {
      xapian: 'Search::Adapters::Xapian::Adapter',
      postgresql: 'Search::Adapters::Postgresql::Adapter'
    }
  end

  def self.backend_for(name)
    class_name = backends.fetch(name.to_sym) do
      raise ArgumentError, "Unknown search backend: #{name.inspect}"
    end
    class_name.constantize.new
  end

  # Apply the configured query backend. Called from the search initializer
  # once the app has booted.
  def self.use_configured_backend!
    self.backend = backend_for(AlaveteliConfiguration.search_backend)
  end

  def self.context(info_request: nil)
    Search::Context::InfoRequest.new(info_request) if info_request
  end

  # Every query method takes an optional +backend+ naming a registered
  # backend to use for that call, overriding the configured SEARCH_BACKEND.
  # This suits callers tied to one backend's features, e.g. admin search
  # relying on the PostgreSQL-only admin index.

  # Direct search - returns a searchable object
  def self.search(query, models:, backend: nil, **options)
    query_backend(backend).search(query, models: models, **options)
  end

  # Search scoped to a relation - returns a chainable ActiveRecord::Relation
  def self.search_scope(query, relation, backend: nil, **options)
    query_backend(backend).search_scope(query, relation, **options)
  end

  # Typeahead search - returns a searchable object
  def self.typeahead(query, model:, backend: nil, **options)
    query_backend(backend).typeahead(query, model: model, **options)
  end

  # Find records similar to the given one - returns a searchable object
  def self.similar(record, backend: nil)
    query_backend(backend).similar(record)
  end

  # Queue a record for a later search index update across every backend
  def self.reindex_later(record)
    backends.keys.map { backend_for(_1) }.each { |b| b.reindex_later(record) }
  end

  # Index job queue count for health monitoring across every backend
  def self.queued_jobs_count
    backends.keys.map { backend_for(_1) }.sum(&:queued_jobs_count)
  end

  # The backend a query method should use: the named one when given,
  # otherwise the configured query backend.
  def self.query_backend(name)
    name ? backend_for(name) : backend
  end
  private_class_method :query_backend
end
