module Search
  module Context
    ##
    # Wraps an InfoRequest to provide context-aware search operations such as
    # finding similar requests, request listings, and recent requests.
    #
    # @example Finding similar requests
    #   context = Search.context(info_request: info_request)
    #   context.similar_requests
    #
    # @example Direct instantiation
    #   context = Search::Context::InfoRequest.new(info_request)
    #   context.similar_requests
    #
    class InfoRequest
      attr_reader :info_request

      def initialize(info_request)
        @info_request = info_request
      end

      def similar_requests
        Search.similar(info_request)
      end

      def request_list(filters, page, per_page, max_results)
        RequestList.new(filters, page, per_page, max_results).call
      end

      def recent_requests
        RecentRequests.new.call
      end
    end
  end
end
