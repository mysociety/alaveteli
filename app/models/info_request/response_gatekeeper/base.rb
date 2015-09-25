# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseGatekeeper
    class Base
      attr_reader :info_request, :allow, :reason

      def initialize(info_request)
        @info_request = info_request
        @allow = true
        @reason = nil
      end

      def allow?(email)
        allow
      end

      def rejection_action
        info_request.handle_rejected_responses
      end
    end
  end
end
