#
# Calculate the pre-tax amount for a subscription with any discounts applied
#
# Example
#
#   # subscription with 50% off 'forever' discount
#   subscription = Stripe::Subscription.retrieve('sub_1234')
#   @subscription = AlaveteliPro::Subscription.new(subscription)
#   @subscription.plan.amount
#   # => 833
#   @subscription.amount
#   # => 416
#   @subscription.discounted?
#   # => true
#   @subscription.free?
#   # => false
module AlaveteliPro::SubscriptionWithDiscount
  def amount
    net = BigDecimal((plan.amount * 0.01), 0).round(2)
    net -= reduction(net)
    (net * 100).floor
  end

  def discounted?
    amount < plan.amount
  end

  def discount_name
    if coupon?
      coupon.id
    elsif trial?
      'PROBETA'
    end
  end

  def free?
    amount == 0
  end

  private

  def coupon?
    !!coupon
  end

  def trial?
    trial_start && trial_end
  end

  def coupon
    @coupon ||= discount.coupon if discount && discount.coupon.valid
  end

  def reduction(net)
    if coupon?
      coupon_reduction(net)
    elsif trial?
      net
    else
      0
    end
  end

  def coupon_reduction(net)
    if coupon.amount_off
      BigDecimal((coupon.amount_off * 0.01), 0).round(2)
    else
      (net * coupon.percent_off / 100)
    end
  end
end
