# == Schema Information
# Schema version: 20230718062820
#
# Table name: account_closure_requests
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :account_closure_request do
  end
end
