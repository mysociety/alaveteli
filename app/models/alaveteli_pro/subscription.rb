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

    private

    def method_missing(*args)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      __getobj__.public_send(*args)
    end
  end
end
