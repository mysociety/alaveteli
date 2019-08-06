# -*- encoding : utf-8 -*-
#
# Calculate amount + 20% tax for a Stripe::Plan or Stripe::Subscription
#
# Example
#
#   plan = Stripe::Plan.retrieve('pro')
#   @plan = WithTax.new(plan)
#   @plan.amount
#   # => 833
#   @plan.amount_with_tax
#   # => 1000
class AlaveteliPro::WithTax < SimpleDelegator
  TAX_RATE = BigDecimal('0.20').freeze

  def amount_with_tax
    # Need to use BigDecimal() here because SimpleDelegator is forwarding
    # `#BigDecimal` to `#amount` in Ruby 2.0.
    net = BigDecimal(amount * 0.01, 0).round(2)
    vat = (net * TAX_RATE).round(2)
    gross = net + vat
    (gross * 100).floor
  end
end
