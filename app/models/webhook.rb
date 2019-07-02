##
# A class which represents a Webhook from a 3rd party service or integration.
#
# Currently the only service which is sending webhooks is Stripe as part of Pro
# pricing.
#
class Webhook < ApplicationRecord
  validates :params, presence: true

  scope :pending_notification, -> { where(notified_at: nil) }

  def date
    Time.at(params['created']) if params['created']
  end

  def customer_id
    object['customer']
  end

  def state
    subscription_state || renewal_state || trial_state || coupon_state ||
      plan_state || _('Unknown webhook ({{id}})', id: params['id'])
  end

  private

  def subscription_state
    if previous['canceled_at'].nil? && object['canceled_at']
      _('Subscription cancelled')
    elsif previous['canceled_at'] && object['canceled_at'].nil?
      _('Subscription reactivated')
    end
  end

  def renewal_state
    if previous['current_period_end'] && object['current_period_start'] &&
       object['status'] == 'active'
      _('Subscription renewed')
    elsif previous['status'] == 'active' && object['status'] == 'past_due'
      _('Subscription renewal failure')
    elsif previous['current_period_end'] && object['current_period_start'] &&
          previous['status'].nil? && object['status'] == 'past_due'
      _('Subscription renewal repeated failure')
    elsif previous['status'] == 'past_due' && object['status'] == 'active'
      _('Subscription renewed after failure')
    end
  end

  def trial_state
    if previous['trial_end'] && object['trial_end'] &&
       previous['trial_end'] < object['trial_end'] &&
       object['status'] == 'trialing'
      _('Trial extended')
    elsif previous['trial_end'] && object['trial_end'] &&
          previous['trial_end'] > object['trial_end'] &&
          object['status'] == 'trialing'
      _('Trial cancelled')
    elsif previous['status'] == 'trialing' && object['status'] == 'active'
      _('Trial ended, first payment succeeded')
    elsif previous['status'] == 'trialing' && object['status'] == 'past_due'
      _('Trial ended, first payment failed')
    end
  end

  def coupon_state
    if previous['discount'].nil? && object['discount']
      _('Coupon code "{{code}}" applied',
        code: object['discount']['coupon']['id']
       )
    elsif previous['discount'] && object['discount'].nil?
      _('Coupon code "{{code}}" revoked',
        code: previous['discount']['coupon']['id']
       )
    end
  end

  def plan_state
    if previous['plan'] && previous['plan'] != object['plan']
      _('Plan changed from "{{from}}" to "{{to}}"',
        from: previous['plan']['name'],
        to: object['plan']['name']
       )
    end
  end

  def object
    params.dig('data', 'object') || {}
  end

  def previous
    params.dig('data', 'previous_attributes') || {}
  end
end
