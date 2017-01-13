module ActivityList
  class RequestSent < Item

    def description
      N_('You sent a request "{{info_request_title}}" to {{public_body_name}}.')
    end

    def call_to_action_url
      info_request_path
    end

  end
end
