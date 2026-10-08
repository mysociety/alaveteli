module Search
  module Adapters
    module Postgresql
      ##
      # Full-text search over one model's public index for PostgreSQL, one
      # result per record, best match first.
      #
      class FullTextSearch < Search::Adapter
        def initialize(query, models:, sort_by: nil, sort_ascending: true)
          models = Array(models)
          unless models.one?
            raise ArgumentError, 'PostgreSQL searches one model at a time'
          end

          @model = models.first
          @sort_by = sort_by
          @sort_ascending = sort_ascending
          super(query, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          relation = sorted(
            SearchDocument.hybrid_search(query, model: @model, limit: 1000)
          )

          create_search_results(
            items: relation.offset(offset).limit(per_page).
              map { |record| { model: record } },
            total_estimate: relation.count,
            current_page: page,
            per_page: per_page,
            offset: offset,
            has_normal_search_terms: query.present?
          )
        end

        private

        # Xapian treats an ascending sort as newest first, so callers pass
        # true to mean descending. Models without the column keep their
        # ranking.
        def sorted(relation)
          return relation unless @model.column_names.include?(@sort_by)

          relation.
            reorder(@sort_by => @sort_ascending ? :desc : :asc).
            order(id: :desc)
        end
      end
    end
  end
end
