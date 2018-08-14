# == Schema Information
#
# Table name: announcements
#
#  id         :integer          not null, primary key
#  visibility :string
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :announcement do
    user
    visibility 'everyone'
    title 'Introducing projects'
    content 'We’re delighted to announce we’ve rolled out the new projects'

    transient do
      dismissed_by nil
    end

    after(:create) do |announcement, evaluator|
      [evaluator.dismissed_by].flatten.compact.each do |user|
        announcement.dismissals.create(user: user)
      end
    end
  end
end
