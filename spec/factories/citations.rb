# == Schema Information
#
# Table name: citations
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  citable_type :string
#  citable_id   :integer
#  source_url   :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :citation do
    user
    association :citable, factory: :info_request
    source_url { 'http://example.com' }
    type { 'other' }

    trait :for_info_request do
      association :citable, factory: :info_request
    end

    trait :for_info_request_batch do
      association :citable, factory: :info_request_batch
    end
  end
end
