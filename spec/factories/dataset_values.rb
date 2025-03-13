# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_values
#
#  id                   :bigint           not null, primary key
#  dataset_value_set_id :bigint
#  dataset_key_id       :bigint
#  value                :string
#  notes                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

FactoryBot.define do
  factory :dataset_value, class: 'Dataset::Value' do
    association :value_set, factory: :dataset_value_set
    association :key, factory: :dataset_key
    value { '1' }
  end
end
