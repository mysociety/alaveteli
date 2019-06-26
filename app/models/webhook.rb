##
# A class which represents a Webhook from a 3rd party service or integration.
#
# Currently the only service which is sending webhooks is Stripe as part of Pro
# pricing.
#
class Webhook < ApplicationRecord
  validates :params, presence: true

  def date
    Time.at(params['created']) if params['created']
  end

  def customer_id
    object['customer']
  end

  def state
    # fixme
  end

  private

  def object
    params.dig('data', 'object') || {}
  end
end
