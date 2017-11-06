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
#   # => 416
#   @subscription.discounted?
#   # => true
#   @subscription.free?
#   # => false
class AlaveteliPro::SubscriptionWithDiscount < SimpleDelegator
  attr_reader :original_amount, :discount_coupon

  def initialize(subscription)
    super
    @plan = subscription.plan
    @original_amount = subscription.plan.amount
    @discount = subscription.discount
    @discount_coupon = fetch_discount_coupon
  end

  def amount
    net = BigDecimal.new((original_amount * 0.01), 0).round(2)
    if discount_coupon
      if discount_coupon.amount_off
        net =
          net - BigDecimal.new((discount_coupon.amount_off * 0.01), 0).round(2)
      else
        reduction = discount_coupon.percent_off
        net = net - (net * discount_coupon.percent_off / 100)
      end
    end
    (net * 100).floor
  end

  def discounted?
    amount < original_amount
  end

  def free?
    amount == 0
  end

  private

  def fetch_discount_coupon
    discount.coupon if discount && discount.coupon.valid
  end
end
