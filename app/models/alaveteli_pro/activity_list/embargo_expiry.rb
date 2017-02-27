module AlaveteliPro
  module ActivityList
    class EmbargoExpiry < Item

      def description
        N_("Your request to {{public_body_name}} \"{{info_request_title}}\" " \
           "is now public.")
      end

      def call_to_action_url
        info_request_path
      end

    end
  end
end
