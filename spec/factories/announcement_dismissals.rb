# == Schema Information
#
# Table name: announcement_dismissals
#
#  id              :integer          not null, primary key
#  announcement_id :integer          not null
#  user_id         :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :announcement_dismissal do
    announcement
    user
  end
end
