module Search
  class TrackEvents
    ##
    # Resolved TrackThing query:
    #   request:info_request.url_title
    #
    class RequestUpdates < Database
      private

      def events_scope
        InfoRequestEvent.where(info_request: track_thing.info_request)
      end
    end
  end
end
