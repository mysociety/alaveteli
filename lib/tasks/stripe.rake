namespace :stripe do
  desc "Create the Stripe webhook endpoint"
  task create_webhook_endpoint: :environment do
    endpoint = AlaveteliPro::WebhookEndpoints.webhook_endpoint_url

    # Find all hooks that POST to our Alaveteli install
    hooks = AlaveteliPro::WebhookEndpoints.retrieve_all_endpoints_data.
              select { |hook| hook.url == endpoint }

    # If there's no hook that matches our requirements, create it.
    if hooks.empty?
      ret =
        Stripe::WebhookEndpoint.create(url: endpoint,
                                       api_version: Stripe.api_version,
                                       enabled_events: Stripe.webhook_events)

      $stderr.puts 'Webhook endpoint successfully created!'
      $stderr.puts 'Add this line to your general.yml config file:'
      $stderr.puts "  STRIPE_WEBHOOK_SECRET: #{ret.secret}"
    else
      $stderr.puts 'Webhook endpoint already exists, stopping'
    end
  end
end
