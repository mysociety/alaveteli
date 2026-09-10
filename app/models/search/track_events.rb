module Search
  ##
  # The events a track matches, and the words to highlight in them.
  #
  class TrackEvents
    include EventSearch

    def initialize(track_thing, sort_by:, limit:, offset: 0)
      @track_thing = track_thing
      @sort_by = sort_by
      @limit = limit
      @offset = offset
    end

    def events
      @events ||= search.results.map { |result| result[:model] }
    end

    def highlight_words
      search.words_to_highlight
    end

    private

    def search
      @search ||= search_events(@track_thing.track_query,
                                sort_by: @sort_by,
                                limit: @limit,
                                offset: @offset)
    end
  end
end
