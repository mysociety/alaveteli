module Search
  ##
  # The events a track matches, and the words to highlight in them.
  #
  # One subclass per track_type, so each can move off the search index on its
  # own. TrackEvents.for picks the right one.
  #
  class TrackEvents
    extend AlaveteliFeatures::Helpers

    def self.for(track_thing, **options)
      klass = strategy_for(track_thing.track_type)
      klass = Index unless live?(klass)
      klass.new(track_thing, **options)
    end

    def self.strategy_for(track_type)
      const_get(track_type.camelize)
    rescue NameError
      raise ArgumentError, "no strategy for track type #{track_type.inspect}"
    end

    # A strategy that has left the search index only goes live behind the
    # flag. Types still on the index subclass Index, which ignores the flag,
    # so it does nothing until a type has somewhere else to go.
    def self.live?(klass)
      klass <= Index ||
        feature_enabled?(:database_backed_alerts)
    end
    private_class_method :live?

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
