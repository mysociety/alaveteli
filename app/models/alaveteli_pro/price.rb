##
# A wrapper for a Stripe::Price
#
class AlaveteliPro::Price < SimpleDelegator
  extend AlaveteliPro::StripeNamespace
  include AlaveteliPro::StripeNamespace
  include Taxable

  tax :unit_amount

  def self.list
    AlaveteliConfiguration.stripe_price_ids.inject([]) do |arr, id|
      price = retrieve(id)
      arr << price if price
      arr
    end
  end

  def self.retrieve(id)
    new(Stripe::Price.retrieve(add_stripe_namespace(id)))
  rescue Stripe::InvalidRequestError
    nil
  end

  def to_param
    remove_stripe_namespace(id)
  end

  # product
  def product
    @product ||= (
      product_id = __getobj__.product
      Stripe::Product.retrieve(product_id) if product_id
    )
  end
end
