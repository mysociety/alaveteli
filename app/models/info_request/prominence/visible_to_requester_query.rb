# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    # All requests in a state that would allow the request owner to view them.
    class VisibleToRequesterQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(prominence: %w(normal backpage requester_only))
      end
    end
  end
end
