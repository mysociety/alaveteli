module Search
  class TrackEvents
    ##
    # Resolves TrackThing query:
    #   requested_by:user.url_name OR commented_by: user.url_name
    #
    # Note: the space after the `commented_by:` so form of the query never
    # worked. We don't fix that here yet.
    #
    class UserUpdates < Database
      private

      def events_scope
        InfoRequestEvent.
          where(info_requests: { user_id: track_thing.tracked_user_id })
      end
    end
  end
end
