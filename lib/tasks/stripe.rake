namespace :stripe do
  desc "Create the Stripe webhook endpoint"
  task create_webhook_endpoint: :environment do
    endpoint = AlaveteliPro::WebhookEndpoints.webhook_endpoint_url

    # Find all hooks that POST to our Alaveteli install
    hooks = AlaveteliPro::WebhookEndpoints.retrieve_all_endpoints_data.
              select { |hook| hook.url == endpoint }

    matching_hook = hooks.find { |hook| hook.api_version == Stripe.api_version }
    stale_hooks = hooks - [matching_hook]

    if matching_hook
      $stderr.puts 'Webhook endpoint already exists, continuing to cleanup'
    else
      # If there's no hook that matches our requirements, create it.
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
    end

    # cleanup - disable any stale webhooks, ideally we'd delete them but
    # delete was only introduced in stripe-ruby v4.12.0
    stale_hooks.each do |stale|
      Stripe::WebhookEndpoint.update(stale.id, disabled: true)
      $stderr.puts "Cleanup: disabled stale endpoint #{stale.id} for " \
                   "version: #{stale.api_version}"
    end
  end
end
