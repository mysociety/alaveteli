# == Schema Information
# Schema version: 20220322100510
#
# Table name: spam_addresses
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :spam_address do
    sequence(:email) { |n| "spam-#{ n }@example.org" }
  end
end
