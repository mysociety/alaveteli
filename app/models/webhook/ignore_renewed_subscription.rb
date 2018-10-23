class Webhook
  class IgnoreRenewedSubscription
    include Webhook::Base

    register 'customer.subscription.updated', if: lambda { |data|
      data[:previous_attributes][:current_period_start] &&
        data[:previous_attributes][:current_period_end]
    }

    def process
      # noop
    end
  end
end
