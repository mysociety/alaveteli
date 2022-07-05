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
      status == 'paid'
    end

    # attributes
    def date
      Time.at(super).to_date
    end

    # charge
    def charge
      @charge ||= Stripe::Charge.retrieve(__getobj__.charge)
    end

    delegate :receipt_url, to: :charge

    private

    def method_missing(*args)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      __getobj__.public_send(*args)
    end
  end
end
