require 'stripe_mock/request_handlers/subscriptions.rb'

# Monkeypatch StripeMock to allow mocking a past_due subscription status
module StripeMock
  ##
  # helper method to set the status to 'past_due'
  def self.mark_subscription_as_past_due(subscription)
    ::Stripe::Subscription.update(subscription.id,
                                  metadata: { marked_past_due: true })
  end

  module RequestHandlers::Subscriptions
    # copies current method and adds a call to our
    # set_custom_status_from_metatdata method to set the status
    # from the stored info in the subscription metatdata when the
    # subscription is retrieved (including calling #refresh)
    def retrieve_subscription(route, method_url, _params, _headers)
      route =~ method_url

      set_custom_status_from_metadata(subscriptions[$1]) if subscriptions[$1]
      assert_existence :subscription, $1, subscriptions[$1]
    end

    # copies current method and adds a call to our
    # set_custom_status_from_metatdata method to set the status
    # from the stored info in the subscription metatdata when multiple
    # subscriptions are retrieved (including from `Subscription::List`)
    def retrieve_subscriptions(route, method_url, params, _headers)
      route =~ method_url

      subscriptions.values.each do |subscription|
        set_custom_status_from_metadata(subscription)
      end

      Data.mock_list_object(subscriptions.values, params)
    end

    private

    def set_custom_status_from_metadata(subscription)
      if subscription[:metadata][:marked_past_due]
        subscription.merge!(status: 'past_due')
      end
    end
  end
end
