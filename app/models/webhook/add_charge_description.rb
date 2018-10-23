class Webhook
  class AddChargeDescription
    include Webhook::Base

    register 'invoice.payment_succeeded'

    def process
      return unless charge && subscription

      plan_name = subscription.plan.name

      charge.description =
        "#{ AlaveteliConfiguration.pro_site_name }: #{ plan_name }"

      charge.save
    end

    private

    def charge
      @charge ||= (
        id = data.object.charge
        Stripe::Charge.retrieve(id) if id
      )
    end

    def subscription
      @subscription ||= (
        id = data.object.subscription
        Stripe::Subscription.retrieve(id) if id
      )
    end
  end
end
