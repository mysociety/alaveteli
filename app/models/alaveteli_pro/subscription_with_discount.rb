# -*- encoding : utf-8 -*-
#
# Calculate the pre-tax amount for a subscription with any discounts applied
#
# Example
#
#   # subscription with 50% off 'forever' discount
#   subscription = Stripe::Subscription.retrieve('sub_1234')
#   @subscription = SubscriptionWithDiscount.new(subscription)
#   @subscription.original_amount
#   # => 833
#   @subscription.amount
#   # => 416.5
class AlaveteliPro::SubscriptionWithDiscount < SimpleDelegator
  attr_reader :original_amount

  def initialize(subscription)
    @plan = subscription.plan
    @original_amount = subscription.plan.amount
    @discount = subscription.discount
    super
  end

  def amount
    net = BigDecimal.new(original_amount * 0.01, 0).round(2)
    discount_coupon = fetch_discount_coupon
    if discount_coupon
      if discount_coupon.amount_off
        net =
          net - BigDecimal.new(discount_coupon.amount_off * 0.01, 0).round(2)
      else
        reduction = discount_coupon.percent_off
        net = net - (net * discount_coupon.percent_off / 100)
      end
    end
    (net * 100)
  end

  private

  def fetch_discount_coupon
    if discount && discount.coupon.valid
      discount.coupon
    end
  end
end
