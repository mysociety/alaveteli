namespace :stripe do
  desc "Create the Stripe webhook endpoint"
  task create_webhook_endpoint: :environment do
    endpoint = AlaveteliPro::WebhookEndpoints.webhook_endpoint_url

    # Find all hooks that POST to our Alaveteli install
    hooks = AlaveteliPro::WebhookEndpoints.retrieve_all_endpoints_data.
              select { |hook| hook.url == endpoint }

    # If there's no hook that matches our requirements, create it.
    if hooks.empty?
      Stripe::WebhookEndpoint.create(url: endpoint,
                                     api_version: Stripe.api_version,
                                     enabled_events: [
                                       'customer.subscription.deleted',
                                       'invoice.payment_succeeded',
                                       'invoice.payment_failed',
                                       'customer.subscription.updated'
                                     ]
                                    )
      $stderr.puts 'Webhook endpoint successfully created!'
    else
      $stderr.puts 'Webhook endpoint already exists, stopping'
    end
  end
end
