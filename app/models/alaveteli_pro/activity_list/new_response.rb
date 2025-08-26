module AlaveteliPro
  module ActivityList
    class NewResponse < Item

      def description
        N_('Your request to {{public_body_name}} "{{info_request_title}}" received a new response.')
      end

      def call_to_action_url
        incoming_message_path(event.incoming_message)
      end

    end
  end
end
