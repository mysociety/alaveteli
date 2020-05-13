FactoryBot.define do
  factory :project do
    title { 'Important FOI Project' }
    briefing { '<p>Please help analyse these info requests</p>' }

    association :owner, factory: :pro_user

    transient do
      contributors_count { 0 }
      requests_count { 0 }
      batches_count { 0 }
    end

    after(:build) do |project, evaluator|
      evaluator.contributors_count.times do
        project.contributors.build(attributes_for(:user))
      end

      evaluator.requests_count.times do
        project.requests.build(
          attributes_for(:info_request).merge(
            user: project.owner,
            public_body: build(:public_body)
          )
        )
      end

      evaluator.batches_count.times do
        project.batches.build(
          attributes_for(:info_request_batch).merge(user: project.owner)
        )
      end
    end

    trait :with_key_set do
      association :key_set, factory: :dataset_key_set
    end
  end
end
