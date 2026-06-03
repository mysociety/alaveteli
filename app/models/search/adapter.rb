module Search
  ##
  # Base service class for search operations. Provides common functionality
  # and interface patterns for different types of searches.
  #
  class Adapter
    attr_reader :query, :options

    def initialize(query = nil, options = {})
      @query = query
      @options = default_options.merge(options)
    end

    # Main results method - should be implemented by subclasses
    def results(page: 1, per_page: 10, **additional_options)
      raise NotImplementedError, 'Subclasses must implement the results method'
    end

    # Quick search for limited results (backwards compatibility)
    def first(limit = 10)
      paginated = results(page: 1, per_page: limit)
      [paginated.items, paginated.has_more?]
    end

    protected

    def default_options
      {
        include_hidden: false,
        sort_order: :relevance
      }
    end

    def create_search_results(items:, total_estimate:, current_page: 1,
                              per_page: 10, offset: 0, **extra)
      Results.new(
        items: items,
        total_estimate: total_estimate,
        current_page: current_page,
        per_page: per_page,
        offset: offset,
        **extra
      )
    end

    def calculate_offset(page, per_page)
      (page - 1) * per_page
    end

    def load_info_requests(ids)
      return [] if ids.empty?

      InfoRequest.includes(public_body: :translations).where(id: ids)
    end
  end
end
