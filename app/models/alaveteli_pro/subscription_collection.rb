module AlaveteliPro
  ##
  # This class is responsible for loading and wrapping Stripe subscriptions as
  # AlaveteliPro::Subscription objects. This allows us to easily customise
  # behaviour and add helper methods.
  #
  class SubscriptionCollection
    include Enumerable

    def self.for_customer(customer)
      new(customer)
    end

    def initialize(customer)
      @customer = customer
    end

    def build
      AlaveteliPro::Subscription.new(
        Stripe::Subscription.new.tap do |subscription|
          subscription.update_attributes(customer: @customer)
        end
      )
    end

    def retrieve(id)
      return unless @customer
      AlaveteliPro::Subscription.new(subscriptions.retrieve(id))
    end

    # scope
    def active
      select(&:active?)
    end

    def past_due
      select(&:past_due?)
    end

    def incomplete
      select(&:incomplete?)
    end

    # enumerable
    def each(&block)
      if block_given?
        wrapped_block = -> (subscription) do
          block.call(AlaveteliPro::Subscription.new(subscription))
        end

        if subscriptions.is_a?(Stripe::ListObject)
          subscriptions.auto_paging_each(&wrapped_block)
        else
          subscriptions.each(&wrapped_block)
        end
      else
        to_enum(:each)
      end
    end

    private

    def subscriptions
      return [] unless @customer
      @customer.subscriptions
    end
  end
end
