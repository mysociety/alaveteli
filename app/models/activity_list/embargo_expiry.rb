module ActivityList
  class EmbargoExpiry < Item

    def description
      N_('The embargo for your request to {{public_body_name}}' \
         ' "{{info_request_title}}" has ended so the request is now public.')
    end

    def call_to_action_url
      info_request_path
    end

  end
end
