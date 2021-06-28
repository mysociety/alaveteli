module AlaveteliPro
  module ActivityList
    class VeryOverdue < Item

      def description
        N_('{{public_body_name}} became long overdue in responding to your request "{{info_request_title}}".')
      end

      def call_to_action
        _("Request an internal review")
      end

      def call_to_action_url
        new_request_followup_path(:request_id => event.info_request.id,
                                  :anchor => 'followup',
                                  :internal_review => 1)
      end

    end
  end
end
