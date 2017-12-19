FactoryGirl.define do
  factory :announcement do
    user
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
