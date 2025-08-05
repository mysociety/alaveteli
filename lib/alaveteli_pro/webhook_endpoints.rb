module AlaveteliPro
  ##
  # A class for working with the Stripe WebhookEndpoints API
  class WebhookEndpoints
    ##
    # Calculates the URL of the Stripe webhook endpoint for the install
    def self.webhook_endpoint_url
      options = {
        host: AlaveteliConfiguration.domain,
        protocol: AlaveteliConfiguration.force_ssl ? 'https' : 'http',
        locale: false
      }

      Rails.application.routes.url_helpers.
        pro_subscriptions_stripe_webhook_url(options)
    end

    ##
    # Helper method to juggle retrieving all the endpoints from the API
    # (not that we're expecting there to be 100s of endpoints to navigate)
    def self.retrieve_all_endpoints_data
      list = retrieve_endpoints
      data = list.data
      while list.has_more
        list = retrieve_endpoints(data.last.id)
        data += list.data
      end
      data
    end

    ##
    # Simple wrapper for Stripe's list method to pull down the maximum
    # allowed number of endpoints in a single call
    def self.retrieve_endpoints(starting_after = nil)
      Stripe::WebhookEndpoint.list(limit: 100, starting_after: starting_after)
    end
  end
end
