module ToDoList
  class ExpiringEmbargo < Item

    def description
      n_("{{count}} embargo is ending this week.",
         "{{count}} embargoes are ending this week.",
         count,
         :count => count)
    end

    def items
      @items ||= user.embargoes.expiring
    end

    def url
      if count > 1
        alaveteli_pro_info_requests_path('request_filter[filter]' => 'embargoes_expiring')
      else
        show_request_path(items.first.info_request.url_title)
      end
    end

    def call_to_action
      n_("Extend or approve this embargo.",
         "Extend or approve these embargoes.",
         count)
    end
  end
end
