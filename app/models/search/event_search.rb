module Search
  ##
  # Shared helper for querying InfoRequestEvents through the backend-agnostic
  # full-text search, converting offset/limit into page/per_page.
  #
  module EventSearch
    private

    def search_events(query, opts = {})
      defaults = {
        offset: 0,
        limit: 20,
        sort_by: 'created_at',
        sort_ascending: true
      }
      opts = defaults.merge(opts)

      per_page = opts[:limit]
      page = (opts[:offset] / per_page) + 1

      Search.search(query, models: [InfoRequestEvent],
                           sort_by: opts[:sort_by],
                           sort_ascending: opts[:sort_ascending],
                           collapse_by: opts[:collapse_by]).
        results(page: page, per_page: per_page)
    end
  end
end
