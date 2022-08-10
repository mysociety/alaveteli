# == Schema Information
# Schema version: 20220720085105
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  body         :text
#

FactoryBot.define do
  factory :note do
    body { 'Test note' }
    association :notable, factory: :public_body

    trait :for_public_body do
      association :notable, factory: :public_body
    end
  end
end
