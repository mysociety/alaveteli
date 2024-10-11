##
# A wrapper for a Stripe::Coupon
#
class AlaveteliPro::Coupon < SimpleDelegator
  extend AlaveteliPro::StripeNamespace
  include AlaveteliPro::StripeNamespace

  def self.referral
    id = add_stripe_namespace(AlaveteliConfiguration.pro_referral_coupon)
    retrieve(id) if id
  end

  def self.retrieve(id)
    new(Stripe::Coupon.retrieve(add_stripe_namespace(id)))
  rescue Stripe::InvalidRequestError
    nil
  end

  def to_param
    remove_stripe_namespace(id)
  end

  def terms
    metadata.humanized_terms || name
  end
end
