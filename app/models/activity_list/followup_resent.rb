module ActivityList
  class FollowupResent < Item

    def description
      case event.calculated_state
      when 'internal_review'
        N_('Your internal review request to {{public_body_name}} for "{{info_request_title}}" was resent.')
      when 'waiting_response'
        N_('Your clarification to {{public_body_name}} for "{{info_request_title}}" was resent.')
      else
        N_('Your follow up to {{public_body_name}} on "{{info_request_title}}" was resent.')
      end
    end

    def call_to_action_url
      outgoing_message_path(event.outgoing_message)
    end

  end
end
