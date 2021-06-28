module AlaveteliPro
  module ActivityList

    class List
      attr_accessor :user, :page, :per_page

      def initialize(user, page, per_page)
        @user = user
        @page = page
        @per_page = per_page
      end

      def event_types
        activity_types.keys
      end

      def events
        user.info_request_events.where(:event_type => event_types)
      end

      def current_items
        current_events = events.paginate :page => page,
                                         :per_page => per_page
        current_events.map { |event| activity_types[event.event_type].new(event) }
      end

      private

      def activity_types
        {
          "sent" => ActivityList::RequestSent,
          "resent" => ActivityList::RequestResent,
          "followup_sent" => ActivityList::FollowupSent,
          "followup_resent" => ActivityList::FollowupResent,
          "response" => ActivityList::NewResponse,
          "comment" => ActivityList::Comment,
          "overdue" => ActivityList::Overdue,
          "very_overdue" => ActivityList::VeryOverdue,
          "embargo_expiry" => ActivityList::EmbargoExpiry
        }
      end

    end
  end
end
