module ToDoList
  class OverdueRequest < Item

    def description
      n_("{{count}} request is overdue.",
         "{{count}} requests are overdue.",
         count,
         :count => count)
    end

    def items
      @items ||= user.info_requests.overdue
    end

    def url
      if count > 1
        alaveteli_pro_info_requests_path('request_filter[filter]' => 'overdue')
      else
        show_request_path(items.first.url_title)
      end
    end

    def call_to_action
      n_("Send a follow up (or request an internal review).",
         "Send follow ups (or request internal reviews).",
         count)
    end
  end
end
