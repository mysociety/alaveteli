module Search
  class TrackEvents
    ##
    # Runs the track's own query string through the search index, whichever
    # backend SEARCH_BACKEND names.
    #
    # The fallback every track type starts on, and the only way to answer a
    # saved search that carries free text.
    #
    class Index < TrackEvents
      include EventSearch

      def events
        @events ||= search.results.map { |result| result[:model] }
      end

      def highlight_words
        search.words_to_highlight
      end

      private

      def search
        @search ||= search_events(track_thing.track_query,
                                  sort_by: sort_by,
                                  limit: limit,
                                  offset: offset)
      end
    end
  end
end
