# == Schema Information
# Schema version: 20230222154014
#
# Table name: user_messages
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :user_message do
    user
  end
end
