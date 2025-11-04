# == Schema Information
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  style        :string           default("original"), not null
#  body         :text
#

FactoryBot.define do
  factory :note do
    rich_body { 'Test note' }
    association :notable, factory: :public_body
    notable_tag { 'some_tag' }
    style { 'blue' }

    trait :for_public_body do
      association :notable, factory: :public_body
      notable_tag { nil }
    end

    trait :tagged do
      notable { nil }
      notable_tag { 'foo' }
    end

    trait :original do
      body { 'Test note' }
      style { 'original' }
    end
  end
end
