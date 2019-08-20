class ProSubscription < SimpleDelegator
  def active?
    status == 'active'
  end

  def incomplete?
    status == 'incomplete'
  end

  def latest_invoice
    @latest_invoice ||= Stripe::Invoice.retrieve(__getobj__.latest_invoice)
  end

  def invoice_open?
    incomplete? && latest_invoice && latest_invoice.status == 'open'
  end

  def payment_intent
    return unless latest_invoice

    @payment_intent ||= Stripe::PaymentIntent.retrieve(
      latest_invoice.payment_intent
    )
  end

  def require_authorisation?
    incomplete? &&
      payment_intent &&
      %w[requires_source_action require_action].include?(payment_intent.status)
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

    def incomplete
      self.class.new(@customer, select(&:incomplete?))
    end

    def retrieve(id)
      find { |subscription| subscription.id == id }
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
