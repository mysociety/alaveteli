##
# A wrapper for a Stripe::Plan
#
class AlaveteliPro::Plan < SimpleDelegator
  extend AlaveteliPro::StripeNamespace
  include AlaveteliPro::StripeNamespace
  include Taxable

  tax :amount

  def self.list
    [retrieve('pro')]
  end

  def self.retrieve(id)
    new(Stripe::Plan.retrieve(add_stripe_namespace(id)))
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
