module Search
  ##
  # The events a track matches, and the words to highlight in them.
  #
  # One subclass per track_type, so each can move off the search index on its
  # own. TrackEvents.for picks the right one.
  #
  class TrackEvents
    def self.for(track_thing, **options)
      strategy_for(track_thing.track_type).new(track_thing, **options)
    end

    def self.strategy_for(track_type)
      const_get(track_type.camelize)
    rescue NameError
      raise ArgumentError, "no strategy for track type #{track_type.inspect}"
    end

    def initialize(track_thing, sort_by:, limit:, offset: 0)
      @track_thing = track_thing
      @sort_by = sort_by
      @limit = limit
      @offset = offset
    end

    def events
      raise NotImplementedError
    end

    def highlight_words
      []
    end

    private

    attr_reader :track_thing, :sort_by, :limit, :offset
  end
end
