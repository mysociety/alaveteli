# == Schema Information
# Schema version: 20220322100510
#
# Table name: pro_accounts
#
#  id                       :bigint           not null, primary key
#  user_id                  :bigint           not null
#  default_embargo_duration :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  stripe_customer_id       :string
#

FactoryBot.define do

  factory :pro_account do
    association :user, factory: :pro_user
  end

end
