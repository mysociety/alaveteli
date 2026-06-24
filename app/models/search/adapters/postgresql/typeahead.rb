module Search
  module Adapters
    module Postgresql
      ##
      # Prefix autocomplete over the +search_documents+ content vector.
      #
      # The query is tokenised to word characters and turned into a prefix
      # tsquery (earlier tokens matched whole, the final token matched as a
      # +term:*+ prefix), matched against +content_tsv+ and joined back to the
      # model. Building the tsquery from word characters only keeps it
      # injection- and syntax-safe.
      #
      # +exclude_tags+ is accepted for interface parity with the Xapian
      # typeahead; per-model tag filtering is follow-on work.
      #
      class Typeahead < Adapter
        attr_reader :query_string, :model, :exclude_tags

        def initialize(query_string, model:, exclude_tags: [], language: nil)
          @query_string = query_string
          @model = model
          @exclude_tags = Array(exclude_tags)
          @language = language
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          scope = matches
          records = scope.offset(offset).limit(per_page).to_a

          create_search_results(
            # mirror the Xapian typeahead result shape: each item is a hash
            # carrying the matched record under :model.
            items: records.map { |record| { model: record } },
            total_estimate: scope.count,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        private

        def matches
          return @model.none if tsquery.blank?

          @model.
            joins(:search_documents).
            where(
              'search_documents.content_tsv @@ to_tsquery(?, ?)',
              language, tsquery
            ).
            distinct
        end

        def language
          @language || Searchable.lang_from_locale(
            AlaveteliLocalization.default_locale
          )
        end

        def tsquery
          tokens = @query_string.to_s.scan(/[[:word:]]+/)
          return '' if tokens.empty?

          prefixed = "#{tokens.pop}:*"
          (tokens + [prefixed]).join(' & ')
        end
      end
    end
  end
end
