# == Schema Information
# Schema version: 20200501183111
#
# Table name: dataset_keys
#
#  id                 :integer          not null, primary key
#  dataset_key_set_id :integer
#  title              :string
#  format             :string
#  order              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :dataset_key, class: 'Dataset::Key' do
    association :key_set, factory: :dataset_key_set
    title { 'Were there any errors?' }
    sequence :order

    boolean

    trait :text do
      format { 'text' }
    end

    trait :numeric do
      format { 'numeric' }
    end

    trait :boolean do
      format { 'boolean' }
    end

    transient do
      value_count { 0 }
    end

    after(:create) do |key, evaluator|
      create_list(:dataset_value, evaluator.value_count, key: key)
    end
  end
end
