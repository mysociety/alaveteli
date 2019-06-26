FactoryBot.define do
  factory :webhook do
    params('type' => 'payment')
    notified_at nil
  end
end
