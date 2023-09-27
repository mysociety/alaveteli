# == Schema Information
# Schema version: 20220210120801
#
# Table name: incoming_messages
#
#  id                             :integer          not null, primary key
#  info_request_id                :integer          not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  raw_email_id                   :integer          not null
#  cached_attachment_text_clipped :text
#  cached_main_body_text_folded   :text
#  cached_main_body_text_unfolded :text
#  subject                        :text
#  from_email_domain              :text
#  valid_to_reply_to              :boolean
#  last_parsed                    :datetime
#  from_name                      :text
#  sent_at                        :datetime
#  prominence                     :string           default("normal"), not null
#  prominence_reason              :text
#  from_email                     :text
#

FactoryBot.define do

  factory :incoming_message do
    info_request
    association :raw_email, strategy: :create
    last_parsed { 1.week.ago }
    sent_at { 1.week.ago }

    transient do
      foi_attachments_factories { [] }
    end

    after(:build) do |incoming_message, evaluator|
      foi_attachments_factories = [[:body_text]]
      foi_attachments_factories += evaluator.foi_attachments_factories
      foi_attachments_factories.each.with_index(1) do |factory, index|
        incoming_message.foi_attachments << build(
          *factory,
          incoming_message: incoming_message,
          url_part_number: index
        )
      end

      incoming_message.raw_email.incoming_message = incoming_message
      incoming_message.raw_email.data = "somedata"
    end

    trait :unparsed do
      last_parsed { nil }
      sent_at { nil }
    end

    trait :hidden do
      prominence { 'hidden' }
    end

    factory :plain_incoming_message do
      last_parsed { nil }
      sent_at { nil }

      after(:create) do |incoming_message, _evaluator|
        data = load_file_fixture('incoming-request-plain.email')
        data.gsub!('EMAIL_FROM', 'Bob Responder <bob@example.com>')
        incoming_message.raw_email.data = data
        incoming_message.raw_email.save!
      end
    end

    factory :incoming_message_with_html_attachment do
      foi_attachments_factories { [[:html_attachment]] }
    end

    factory :incoming_message_with_pdf_attachment do
      foi_attachments_factories { [[:pdf_attachment]] }
    end
  end
end
