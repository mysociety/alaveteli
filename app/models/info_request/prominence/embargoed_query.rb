# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class EmbargoedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.includes(:embargo).where('embargoes.id IS NOT NULL')
      end
    end
  end
end
