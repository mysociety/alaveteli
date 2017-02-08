module AlaveteliPro
  module ToDoList
    class NewResponse < Item

      def description
        n_("{{count}} request has received a response.",
           "{{count}} requests have received a response.",
           count,
           :count => count)
      end

      def items
        @items ||= user.info_requests.response_received
      end

      def url
        if count > 1
          alaveteli_pro_info_requests_path('request_filter[filter]' => 'response_received')
        else
          show_request_path(items.first.url_title)
        end
      end

      def call_to_action
        n_("Update its status.",
           "Update statuses.",
           count)
      end

    end
  end
end
