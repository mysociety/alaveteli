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
#   @subscription.discounted_amount
#   # => 416
#   @subscription.discounted?
#   # => true
#   @subscription.free?
#   # => false
module AlaveteliPro::Subscription::Discount
  def discounted_amount
    plan.amount - reduction
  end

  def discounted?
    discounted_amount < plan.amount
  end

  def discount_name
    if coupon?
      coupon.id
    elsif trial?
      'PROBETA'
    end
  end

  def free?
    discounted_amount == 0
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

  def reduction
    if coupon?
      coupon_reduction
    elsif trial?
      plan.amount
    else
      0
    end
  end

  def coupon_reduction
    if coupon.amount_off
      coupon.amount_off
    else
      (plan.amount * coupon.percent_off / 100)
    end
  end
end
