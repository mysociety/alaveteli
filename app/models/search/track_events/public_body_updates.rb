module Search
  class TrackEvents
    ##
    # Resolves TrackThink query:
    #   requested_from: Every request made to one authority.
    #   variety: Events of a given type
    #
    class PublicBodyUpdates < Database
      private

      def events_scope
        scope = InfoRequestEvent.
          where(info_requests: { public_body_id: track_thing.public_body_id })

        event_type = variety_from_track_query
        event_type ? scope.where(event_type: event_type) : scope
      end

      def variety_from_track_query
        track_thing.track_query[/\bvariety:(\w+)/, 1]
      end
    end
  end
end
