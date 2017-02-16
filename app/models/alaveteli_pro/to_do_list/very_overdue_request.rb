module AlaveteliPro
  module ToDoList
    class VeryOverdueRequest < Item

      def description
        n_("{{count}} request is very overdue.",
           "{{count}} requests are very overdue.",
           count,
           :count => count)
      end

      def items
        @items ||= user.info_requests.very_overdue
      end

      def url
        if count > 1
          alaveteli_pro_info_requests_path('alaveteli_pro_request_filter[filter]' =>
                                             'very_overdue')
        else
          show_request_path(items.first.url_title)
        end
      end

      def call_to_action
        n_("Request an internal review (or send another followup).",
           "Request internal reviews (or send other followups).",
           count)
      end
    end
  end
end
