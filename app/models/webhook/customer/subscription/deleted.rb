class Webhook
  module Customer
    module Subscription
      class Deleted
        attr_reader :data

        def initialize(data)
          @data = data
        end

        def process
          customer_id = data.object.customer
          if account = ProAccount.find_by(stripe_customer_id: customer_id)
            account.user.remove_role(:pro)
          end
        end
      end
    end
  end
end
