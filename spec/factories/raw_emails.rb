# == Schema Information
#
# Table name: raw_emails
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  erased_at  :datetime
#

FactoryBot.define do
  factory :raw_email

  trait :with_file do
    transient do
      sequence(:filename) { |n| "#{n + 1}.eml" }
      mail { Mail.new }
    end

    after(:build) do |raw_email, evaluator|
      raw_email.file.attach(
        io: StringIO.new(evaluator.mail.to_s),
        filename: evaluator.filename,
        content_type: 'message/rfc822'
      )
    end
  end
end
