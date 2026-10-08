module Search
  module Adapters
    module Postgresql
      ##
      # Request search for PostgreSQL. Pages SearchDocument.request_search,
      # which returns one InfoRequest per request, best match first.
      #
      class RequestSearch < Search::Adapter
        SORT_COLUMNS = {
          'created_at' => :created_at,
          'described_at' => :last_event_time
        }.freeze

        def initialize(query, sort_by: nil, sort_ascending: true)
          @sort_by = sort_by
          @sort_ascending = sort_ascending
          super(query, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          relation = sorted(SearchDocument.request_search(query))

          create_search_results(
            items: relation.offset(offset).limit(per_page).
              map { |request| { model: request } },
            total_estimate: relation.count,
            current_page: page,
            per_page: per_page,
            offset: offset,
            has_normal_search_terms: query.present?
          )
        end

        private

        # Xapian treats an ascending sort as newest first, so callers pass
        # true to mean descending.
        def sorted(relation)
          return relation unless @sort_by

          column = InfoRequest.arel_table[SORT_COLUMNS.fetch(@sort_by)]
          direction = @sort_ascending ? column.desc : column.asc
          relation.reorder(direction.nulls_last).order(id: :desc)
        end
      end
    end
  end
end
