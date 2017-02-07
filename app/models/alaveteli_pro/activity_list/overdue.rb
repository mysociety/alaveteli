module AlaveteliPro
  module ActivityList
    class Overdue < Item

      def description
        N_('{{public_body_name}} became overdue in responding to your request "{{info_request_title}}".')
      end

      def call_to_action
        _("Send a follow up")
      end

      def call_to_action_url
        new_request_followup_path(:request_id => event.info_request.id, :anchor => 'followup')
      end

    end
  end
end
