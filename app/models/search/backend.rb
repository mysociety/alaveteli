module Search
  ##
  # Abstract base class defining the interface for search backends.
  # Each backend (Xapian, PostgreSQL, etc.) must implement the required
  # methods. Optional methods provide sensible defaults.
  #
  class Backend
    # Required: full-text search returning a searchable object
    def search(query, models:, **options)
      raise NotImplementedError, 'Subclasses must implement #search'
    end

    # Required: typeahead/autocomplete search returning a searchable object
    def typeahead(query, model:, **options)
      raise NotImplementedError, 'Subclasses must implement #typeahead'
    end

    # Required: find records similar to the given one, returning a
    # searchable object
    def similar(record)
      raise NotImplementedError, 'Subclasses must implement #similar'
    end

    # Optional: queue a record for a later search index update.
    # Backends where the search index is the database itself (e.g.
    # PostgreSQL) can leave this as a no-op.
    def reindex_later(record)
      nil
    end

    # Optional: number of index update jobs waiting to be processed.
    # Backends without async indexing return 0.
    def queued_jobs_count
      0
    end
  end
end
