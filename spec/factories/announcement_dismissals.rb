# == Schema Information
# Schema version: 20220322100510
#
# Table name: announcement_dismissals
#
#  id              :bigint           not null, primary key
#  announcement_id :bigint           not null
#  user_id         :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :announcement_dismissal do
    announcement
    user
  end
end
