# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class VisibleQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(prominence: 'normal').not_embargoed
      end
    end
  end
end
