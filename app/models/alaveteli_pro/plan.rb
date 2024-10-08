##
# A wrapper for a Stripe::Plan
#
class AlaveteliPro::Plan < SimpleDelegator
  include Taxable

  tax :amount
end
