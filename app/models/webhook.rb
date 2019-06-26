##
# A class which represents a Webhook from a 3rd party service or integration.
#
# Currently the only service which is sending webhooks is Stripe as part of Pro
# pricing.
#
class Webhook < ApplicationRecord
  validates :params, presence: true
end
