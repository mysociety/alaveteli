module Search
  class TrackEvents
    ##
    # Resolves TrackThing query:
    #   variety:response (status:successful OR status:partially_successful)
    #
    class AllSuccessfulRequests < Database
      SUCCESSFUL_STATES = %w[successful partially_successful].freeze

      private

      def events_scope
        InfoRequestEvent.response_events.
          where(calculated_state: SUCCESSFUL_STATES)
      end
    end
  end
end
