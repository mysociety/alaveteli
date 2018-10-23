class Webhook
  module Invoice
    class PaymentSucceeded
      attr_reader :data

      def initialize(data)
        @data = data
      end

      def process
        charge_id = data.object.charge

        if charge_id
          charge = Stripe::Charge.retrieve(charge_id)

          subscription_id = data.object.subscription
          subscription = Stripe::Subscription.retrieve(subscription_id)
          plan_name = subscription.plan.name

          charge.description =
            "#{ AlaveteliConfiguration.pro_site_name }: #{ plan_name }"

          charge.save
        end
      end
    end
  end
end
