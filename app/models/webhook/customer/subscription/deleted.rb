class Webhook
  module Customer
    module Subscription
      class Deleted
        include Webhook::Base

        register 'customer.subscription.deleted'

        def process
          return unless pro_account

          pro_account.user.remove_role(:pro)
        end

        private

        def pro_account
          @pro_account ||= (
            id = data.object.customer
            ProAccount.find_by(stripe_customer_id: id) if id
          )
        end
      end
    end
  end
end
