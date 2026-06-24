module Search
  module Adapters
    module Xapian
      ##
      # Xapian typeahead/autocomplete adapter.
      # Handles query preparation (truncation, wildcard expansion,
      # short-word stripping, exclude-tag building) and executes against
      # the Xapian database, wrapping results as Search::Results.
      #
      # @example Via the Search facade
      #   Search.typeahead('geraldine', model: PublicBody)
      #     .results(page: 1, per_page: 10)
      #
      class Typeahead < Adapter
        attr_reader :query_string, :model, :exclude_tags

        def initialize(query_string, model:, exclude_tags: [])
          @query_string = query_string
          @model = model
          @exclude_tags = Array(exclude_tags)
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          prepare_query
          offset = calculate_offset(page, per_page)

          return empty_results(page, per_page) unless @run_search

          xapian_result = xapian_search(page, per_page)

          create_search_results(
            items: xapian_result.results,
            total_estimate: xapian_result.matches_estimated,
            current_page: page,
            per_page: per_page,
            offset: offset,
            spelling_correction: xapian_result.spelling_correction,
            words_to_highlight: extract_words_to_highlight(xapian_result)
          )
        end

        private

        def prepare_query
          @prepared_query = @query_string.mb_chars.limit(252).strip

          query_words = @prepared_query.split
          if query_words.last && query_words.last.strip.length < 3
            query_words.pop
            @prepared_query = query_words.join
            @wildcard = false
          else
            @wildcard = true
          end

          @run_search = @prepared_query.present?
        end

        def prepared_query_string
          query_str = @wildcard ? "#{@prepared_query}*" : @prepared_query.to_s

          if @exclude_tags.any?
            tag_string = @exclude_tags.map { |tag| "-tag:#{tag}" }.join(' ')
            query_str = "#{query_str} #{tag_string}"
          end

          query_str
        end

        def search_options(page, per_page)
          {
            offset: calculate_offset(page, per_page),
            limit: per_page,
            sort_by_prefix: nil,
            sort_by_ascending: true,
            collapse_by_prefix: collapse_prefix
          }
        end

        def collapse_prefix
          models = Array(@model)
          if models.include?(PublicBody)
            nil
          elsif models.include?(InfoRequestEvent)
            'request_collapse'
          end
        end

        def xapian_search(page, per_page)
          ActsAsXapian.readable_init
          old_default_op = ActsAsXapian.query_parser.default_op
          ActsAsXapian.query_parser.default_op = ::Xapian::Query::OP_OR

          begin
            result = run_query(page, per_page)
          rescue ActsAsXapian::UnhandledRuntimeError => e
            Rails.logger.warn(
              "Wildcard query '#{@prepared_query}' caused: " \
              "#{e.message.force_encoding('UTF-8')}"
            )
            @wildcard = false
            result = run_query(page, per_page)
          end

          ActsAsXapian.query_parser.default_op = old_default_op
          result
        end

        def run_query(page, per_page)
          user_query = ActsAsXapian.query_parser.parse_query(
            prepared_query_string, flags
          )
          ActsAsXapian::Search.new(
            @model, @prepared_query.to_s, search_options(page, per_page),
            user_query
          )
        end

        def flags
          base = ::Xapian::QueryParser::FLAG_LOVEHATE |
                 ::Xapian::QueryParser::FLAG_SPELLING_CORRECTION
          @wildcard ? base | ::Xapian::QueryParser::FLAG_WILDCARD : base
        end

        def empty_results(page, per_page)
          create_search_results(
            items: [],
            total_estimate: 0,
            current_page: page,
            per_page: per_page,
            offset: calculate_offset(page, per_page)
          )
        end

        def extract_words_to_highlight(xapian_result)
          xapian_result.words_to_highlight(include_original: true, regex: true)
        rescue StandardError
          []
        end
      end
    end
  end
end
