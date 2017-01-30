# -*- encoding : utf-8 -*-
class InfoRequest
  class ProQuery
    def initialize(relation = InfoRequest)
      @relation = relation
    end

    def call
      @relation.includes(:user => :pro_account)
        .where('pro_accounts.id IS NOT NULL')
    end
  end
end
