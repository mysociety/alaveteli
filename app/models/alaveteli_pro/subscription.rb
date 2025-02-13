module AlaveteliPro
  ##
  # This class adds wraps a Stripe::Subscription object to customise behaviour
  # and to add useful helper methods.
  #
  class Subscription < SimpleDelegator
    include Subscription::Discount

    # state
    def active?
      status == 'active'
    end

    def incomplete?
      status == 'incomplete'
    end

    # invoice
    def latest_invoice
      @latest_invoice ||= Stripe::Invoice.retrieve(__getobj__.latest_invoice)
    end

    def invoice_open?
      incomplete? && latest_invoice.status == 'open'
    end

    # payment_intent
    def payment_intent
      return unless latest_invoice

      @payment_intent ||= Stripe::PaymentIntent.retrieve(
        latest_invoice.payment_intent
      )
    end

    def require_authorisation?
      invoice_open? && payment_intent.status == 'requires_action'
    end

    def update(attributes)
      __setobj__(Stripe::Subscription.update(id, attributes))
    end

    def delete
      Stripe::Subscription.cancel(id)
    end

    # price
    def price
      @price ||= AlaveteliPro::Price.new(items.first.price)
    end

    private

    def method_missing(method, *args, &block)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      if __getobj__.respond_to?(method)
        __getobj__.public_send(method, *args, &block)
      else
        super
      end
    end
  end
end
