FactoryBot.define do
  factory :project do
    title { 'Important FOI Project' }
    briefing { 'Please help analyse these info requests' }

    association :owner, factory: :pro_user

    transient do
      contributors_count { 0 }
    end

    after(:build) do |project, evaluator|
      evaluator.contributors_count.times do
        project.contributors.build(attributes_for(:user))
      end
    end
  end
end
