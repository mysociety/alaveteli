module AlaveteliPro
  module ActivityList
    class RequestResent < Item

      def description
        N_('Your request "{{info_request_title}}" to {{public_body_name}} was resent.')
      end

      def call_to_action_url
        info_request_path
      end

    end
  end
end
