module Search
  ##
  # Searches for InfoRequestEvents matching the given filters and returns a
  # paginated request list for RequestController#list.
  #
  class RequestList
    include EventSearch

    def initialize(filters, page, per_page, max_results)
      @filters = filters
      @page = page
      @per_page = per_page
      @max_results = max_results
    end

    def call
      query = InfoRequestEvent.make_query_from_params(@filters)

      results = search_events(query,
                              limit: 25,
                              offset: (@page - 1) * @per_page,
                              collapse_by: 'request_collapse')

      list_results = results.results.map { |r| r[:model] }
      matches_estimated = results.matches_estimated
      show_no_more_than = [matches_estimated, @max_results].min
      { results: list_results,
        matches_estimated: matches_estimated,
        show_no_more_than: show_no_more_than }
    end
  end
end
