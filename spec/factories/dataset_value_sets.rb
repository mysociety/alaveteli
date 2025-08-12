# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_value_sets
#
#  id                 :bigint           not null, primary key
#  resource_type      :string
#  resource_id        :bigint
#  dataset_key_set_id :bigint
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :dataset_value_set, class: 'Dataset::ValueSet' do
    association :key_set, factory: :dataset_key_set

    for_info_request

    trait :for_info_request do
      association :resource, factory: :info_request
    end

    trait :for_incoming_message do
      association :resource, factory: :incoming_message
    end

    trait :for_foi_attachment do
      association :resource, factory: :pdf_attachment
    end

    transient do
      value_count { 1 }
    end

    after(:build) do |value_set, evaluator|
      next if value_set.values.count > 0 || evaluator.value_count.zero?
      value_set.values = build_list(
        :dataset_value, evaluator.value_count, value_set: value_set
      )
    end
  end
end
