FactoryBot.define do
  factory :project_resource do
    project
    association :resource, factory: :info_request

    trait :for_info_request do
      association :resource, factory: :info_request
    end

    trait :for_info_request_batch do
      association :resource, factory: :info_request_batch
    end
  end
end
