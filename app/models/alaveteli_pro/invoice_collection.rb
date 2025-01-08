module AlaveteliPro
  ##
  # This class is responsible for loading and wrapping Stripe invoices as
  # AlaveteliPro::Invoice objects. This allows us to easily customise
  # behaviour and add helper methods.
  #
  class InvoiceCollection
    include Enumerable

    def self.for_customer(customer)
      new(customer)
    end

    def initialize(customer)
      @customer = customer
    end

    def retrieve(id)
      return unless @customer

      AlaveteliPro::Invoice.new(invoices.retrieve(id))
    end

    # scope
    def open
      select(&:open?)
    end

    def paid
      select(&:paid?)
    end

    # enumerable
    def each(&block)
      if block_given?
        wrapped_block = -> (invoice) do
          block.call(AlaveteliPro::Invoice.new(invoice))
        end

        if invoices.is_a?(Stripe::ListObject)
          invoices.auto_paging_each(&wrapped_block)
        else
          invoices.each(&wrapped_block)
        end
      else
        to_enum(:each)
      end
    end

    private

    def invoices
      return [] unless @customer

      @invoices ||= Stripe::Invoice.list(customer: @customer.id)
    end
  end
end
