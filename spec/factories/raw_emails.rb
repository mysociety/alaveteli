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

    after(:build) do |foi_attachment, evaluator|
      foi_attachment.file.attach(
        io: StringIO.new(evaluator.mail.to_s),
        filename: evaluator.filename,
        content_type: 'message/rfc822'
      )
    end
  end
end
