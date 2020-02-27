# -*- encoding : utf-8 -*-
class InfoRequest
  class ProQuery
    def initialize(relation = InfoRequest)
      @relation = relation
    end

    def call
      @relation.
        includes(user: :roles).
          where(roles: { name: 'pro' }).
            references(:roles)
    end
  end
end
