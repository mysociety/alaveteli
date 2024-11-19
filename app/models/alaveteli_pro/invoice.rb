module AlaveteliPro
  ##
  # This class adds wraps a Stripe::Invoice object to customise behaviour
  # and to add useful helper methods.
  #
  class Invoice < SimpleDelegator
    # state
    def open?
      status == 'open'
    end

    def paid?
      status == 'paid' && amount_paid > 0
    end

    # attributes
    def created
      Time.at(super).to_date
    end

    # charge
    def charge
      charge_id = __getobj__.charge
      @charge ||= Stripe::Charge.retrieve(charge_id) if charge_id
    end

    delegate :receipt_url, to: :charge, allow_nil: true

    private

    def method_missing(*args)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      __getobj__.public_send(*args)
    end
  end
end
