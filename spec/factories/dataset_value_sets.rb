# == Schema Information
# Schema version: 20200501183111
#
# Table name: dataset_value_sets
#
#  id                 :integer          not null, primary key
#  resource_type      :string
#  resource_id        :integer
#  dataset_key_set_id :integer
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
      value_count { 0 }
    end

    after(:create) do |value_set, evaluator|
      create_list(:dataset_value, evaluator.value_count, value_set: value_set)
    end
  end
end
