# -*- encoding : utf-8 -*-
#
# Calculate amount + 20% tax for a Stripe::Plan
#
# Example
#
#   plan = Stripe::Plan.retrieve('pro')
#   @plan = PlanWithTax.new(plan)
#   @plan.amount
#   # => 833
#   @plan.amount_with_tax
#   # => 1000
class AlaveteliPro::PlanWithTax < SimpleDelegator
  def amount_with_tax
    ((amount * 1.2 / 100).round(2) * 100).floor
  end
end
