# == Schema Information
#
# Table name: citations
#
#  id           :bigint           not null, primary key
#  user_id      :bigint
#  citable_type :string
#  citable_id   :bigint
#  source_url   :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  title        :string
#  description  :text
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
