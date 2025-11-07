# == Schema Information
# Schema version: 20220225214524
#
# Table name: user_sign_ins
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  ip         :inet
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  country    :string
#
FactoryBot.define do
  factory :user_sign_in, class: 'User::SignIn' do
    user
    ip { '0.0.0.0' }
    country { 'XX' }

    trait :ipv4 do
      ip { '0.0.0.0' }
    end

    trait :ipv6 do
      ip { '7754:76d4:c7aa:7646:ea68:1abb:4055:4343' }
    end
  end
end
