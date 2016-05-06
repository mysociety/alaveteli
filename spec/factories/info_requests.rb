# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :info_request do
    sequence(:title) { |n| "Example Title #{n}" }
    public_body
    user

    after(:create) do |info_request, evaluator|
      create(:initial_request, :info_request => info_request)
    end

    factory :info_request_with_incoming do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_plain_incoming do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:plain_incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_incoming_attachments do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:incoming_message_with_attachments, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_internal_review_request do
      after(:create) do |info_request, evaluator|
        outgoing_message = create(:internal_review_request, :info_request => info_request)
      end
    end

    factory :external_request do
      user nil
      external_user_name 'External User'
      external_url 'http://www.example.org/request/external'
    end

  end

end
