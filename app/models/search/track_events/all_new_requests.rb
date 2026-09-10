module Search
  class TrackEvents
    ##
    # Resolves TrackThing query:
    #   variety:sent
    #
    class AllNewRequests < Database
      private

      def events_scope
        InfoRequestEvent.sent_events
      end
    end
  end
end
