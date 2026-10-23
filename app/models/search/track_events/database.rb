module Search
  class TrackEvents
    ##
    # Events straight from the database, for tracks whose query is a
    # structural filter rather than a search.
    #
    # Subclasses say which events the track is about; visibility, order and
    # the pagination are handled here.
    #
    class Database < TrackEvents
      def events
        @events ||= events_scope.
          is_searchable.
          includes(
            :outgoing_message,
            :comment,
            { info_request: [:user, :public_body, :censor_rules] }
          ).
          order(order).
          limit(limit).
          offset(offset)
      end

      private

      def events_scope
        raise NotImplementedError
      end

      # Always newest first. Xapian's sort_ascending is its reverse flag, and
      # every alert passes true, so ascending order has never been asked for.
      # Xapian breaks ties by docid; id is the closest we have.
      def order
        column = :created_at unless sort_by == 'described_at'
        column ||= Arel.sql(
          'COALESCE(info_request_events.last_described_at, ' \
          'info_request_events.created_at)'
        )
        { column => :desc, :id => :desc }
      end
    end
  end
end
