module Search
  ##
  # Shared helper for running a request search through the backend-agnostic
  # interface, converting offset/limit into page/per_page. Results are
  # InfoRequests (one per matching request).
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

      Search.request_search(query,
                            sort_by: opts[:sort_by],
                            sort_ascending: opts[:sort_ascending]).
        results(page: page, per_page: per_page)
    end
  end
end
