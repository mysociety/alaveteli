# -*- encoding : utf-8 -*-
module AlaveteliPro
  module ToDoList
    class ExpiringEmbargo < Item
      def description
        n_("{{count}} request will be made public this week.",
           "{{count}} requests will be made public this week.",
           count,
           count: count)
      end

      def items
        @items ||= user.embargoes.expiring
      end

      def count
        user.phase_counts['embargo_expiring']
      end

      def url
        if count > 1
          alaveteli_pro_info_requests_path('alaveteli_pro_request_filter[filter]' =>
                                             'embargoes_expiring')
        else
          show_request_path(items.first.info_request.url_title)
        end
      end

      def call_to_action
        n_("Publish this request or keep it private for longer.",
           "Publish these requests or keep them private for longer.",
           count)
      end
    end
  end
end
