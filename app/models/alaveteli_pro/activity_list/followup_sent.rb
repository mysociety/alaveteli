module AlaveteliPro
  module ActivityList
    class FollowupSent < Item

      def description
        case event.calculated_state
        when 'internal_review'
          N_('You sent an internal review request to {{public_body_name}} for "{{info_request_title}}".')
        when 'waiting_response'
          N_('You sent a clarification to {{public_body_name}} for "{{info_request_title}}".')
        else
          N_('You sent a follow up to {{public_body_name}} on "{{info_request_title}}".')
        end
      end

      def call_to_action_url
        outgoing_message_path(event.outgoing_message)
      end

    end
  end
end
