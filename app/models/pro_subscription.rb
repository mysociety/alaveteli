class ProSubscription < SimpleDelegator
  def active?
    status == 'active'
  end

  class Collection
    include Enumerable

    def initialize(customer, subscriptions)
      @customer = customer
      @subscriptions = subscriptions
    end

    def active
      self.class.new(@customer, select(&:active?))
    end

    def each(&block)
      if block_given?
        wrapped_block = -> (subscription) do
          block.call(ProSubscription.new(subscription))
        end

        if @subscriptions.kind_of?(Stripe::ListObject)
          @subscriptions.auto_paging_each(&wrapped_block)
        else
          @subscriptions.each(&wrapped_block)
        end
      else
        to_enum(:each)
      end
    end
  end
end
