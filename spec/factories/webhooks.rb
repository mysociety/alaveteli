FactoryBot.define do
  factory :webhook do
    params('type' => 'payment')
    notified_at nil

    transient do
      fixture { nil }
      created { nil }
      customer { nil }
    end

    after(:build) do |webhook, evaluator|
      next unless evaluator.fixture

      path = Rails.root.join('spec', 'fixtures', 'stripe_webhooks',
                             evaluator.fixture + '.json')
      webhook.params = JSON.parse(File.read(path)).to_h
    end

    after(:build) do |webhook, evaluator|
      next unless evaluator.created

      webhook.params['created'] = evaluator.created
    end

    after(:build) do |webhook, evaluator|
      next unless evaluator.customer

      webhook.params['data'] ||= {}
      webhook.params['data']['object'] ||= {}
      webhook.params['data']['object']['customer'] = evaluator.customer
    end
  end
end
