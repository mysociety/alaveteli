module AlaveteliPro
  ##
  # This class adds wraps a Stripe::Subscription object to customise behaviour
  # and to add useful helper methods.
  #
  class Subscription < SimpleDelegator
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
      invoice_open? && %w[
        requires_source_action require_action
      ].include?(payment_intent.status)
    end

    private

    def method_missing(*args)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      __getobj__.public_send(*args)
    end
  end
end
