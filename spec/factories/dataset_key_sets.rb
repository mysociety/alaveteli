# == Schema Information
# Schema version: 20200501183111
#
# Table name: dataset_key_sets
#
#  id            :integer          not null, primary key
#  resource_type :string
#  resource_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :dataset_key_set, class: 'Dataset::KeySet' do
    for_project

    trait :for_project do
      association :resource, factory: :project
    end

    trait :for_info_request do
      association :resource, factory: :info_request
    end

    trait :for_info_request_batch do
      association :resource, factory: :info_request_batch
    end

    transient do
      key_count { 0 }
      value_set_count { 0 }
    end

    after(:create) do |key_set, evaluator|
      create_list(
        :dataset_key,
        evaluator.key_count,
        key_set: key_set
      )
      create_list(
        :dataset_value_set,
        evaluator.value_set_count,
        key_set: key_set
      )
    end
  end
end
