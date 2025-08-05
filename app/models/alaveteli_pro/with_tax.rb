# -*- encoding : utf-8 -*-
#
# Calculate amount + tax for a Stripe::Plan or Stripe::Subscription.
#
# Set STRIPE_TAX_RATE in config/general.yml to change the tax rate.
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
  def amount_with_tax
    # Need to use BigDecimal() here because SimpleDelegator is forwarding
    # `#BigDecimal` to `#amount` in Ruby 2.0.
    net = BigDecimal(amount * 0.01, 0).round(2)
    vat = (net * tax_rate).round(2)
    gross = net + vat
    (gross * 100).floor
  end

  private

  def tax_rate
    @tax_rate ||= BigDecimal(AlaveteliConfiguration.stripe_tax_rate)
  end
end
