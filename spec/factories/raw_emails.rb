# == Schema Information
#
# Table name: raw_emails
#
#  id                :integer          not null, primary key
#  created_at        :datetime
#  updated_at        :datetime
#  from_email        :text
#  from_email_domain :text
#  from_name         :text
#  message_id        :text
#  sent_at           :datetime
#  subject           :text
#  valid_to_reply_to :boolean
#

FactoryBot.define do
  factory :raw_email

  trait :with_file do
    transient do
      sequence(:filename) { |n| "#{n + 1}.eml" }
      mail { Mail.new }
    end

    after(:build) do |raw_email, evaluator|
      data_string = evaluator.mail.to_s
      raw_email.instance_variable_set(:@data, data_string)
      raw_email.file.attach(
        io: StringIO.new(data_string),
        filename: evaluator.filename,
        content_type: 'message/rfc822'
      )
    end
  end
end
