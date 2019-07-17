##
# A class which represents a simple log of a Webhook from a 3rd party service
# or integration which has been processed by the app so we can filter out
# duplicates events.
#
# Currently the only service which is sending webhooks is Stripe as part of Pro
# pricing.
#
class ProcessedWebhook < ApplicationRecord
end
