module Search
  module Adapters
    module Postgresql
      ##
      # Similar requests for PostgreSQL. Searches for requests matching any
      # word of the request's title, best match first, leaving out the
      # request itself.
      #
      class SimilarRequests < Search::Adapter
        attr_reader :info_request

        def initialize(info_request)
          @info_request = info_request
          super(title_query, {})
        end

        def results(page: 1, per_page: 10)
          offset = calculate_offset(page, per_page)
          relation = similar

          create_search_results(
            items: relation.offset(offset).limit(per_page).
              includes(public_body: :translations).to_a,
            total_estimate: relation.count,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        private

        def similar
          return InfoRequest.none if query.blank?

          SearchDocument.request_search(
            query,
            requests: InfoRequest.is_searchable.where.not(id: info_request.id)
          )
        end

        # Strip punctuation so websearch_to_tsquery can't read quotes or a
        # leading minus as operators, and drop "or" so it stays a word.
        def title_query
          info_request.title.to_s.scan(/[[:alnum:]]+/).
            reject { _1.casecmp?('or') }.
            join(' OR ')
        end
      end
    end
  end
end
