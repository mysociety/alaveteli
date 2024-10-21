##
# A wrapper for a Stripe::Price
#
class AlaveteliPro::Price < SimpleDelegator
  extend AlaveteliPro::StripeNamespace
  include AlaveteliPro::StripeNamespace
  include Taxable

  tax :unit_amount

  def self.list
    AlaveteliConfiguration.stripe_prices.inject([]) do |arr, (_, id)|
      arr << retrieve(id)
      arr
    end
  end

  def self.retrieve(id)
    new(Stripe::Price.retrieve(add_stripe_namespace(id, prefix: 'price')))
  end

  def to_param
    AlaveteliConfiguration.stripe_prices[id]
  end

  def ===(other)
    self.id == other.id
  end

  # product
  def product
    @product ||= (
      product_id = __getobj__.product
      Stripe::Product.retrieve(product_id) if product_id
    )
  end
end
