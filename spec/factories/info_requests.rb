# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :info_request do
    sequence(:title) { |n| "Example Title #{n}" }
    public_body
    user

    after_create do |info_request, evaluator|
      FactoryGirl.create(:initial_request, :info_request => info_request)
    end

    factory :info_request_with_incoming do
      after_create do |info_request, evaluator|
        incoming_message = FactoryGirl.create(:incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_plain_incoming do
      after_create do |info_request, evaluator|
        incoming_message = FactoryGirl.create(:plain_incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_incoming_attachments do
      after_create do |info_request, evaluator|
        incoming_message = FactoryGirl.create(:incoming_message_with_attachments, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_internal_review_request do
      after_create do |info_request, evaluator|
        outgoing_message = FactoryGirl.create(:internal_review_request, :info_request => info_request)
      end
    end

    factory :external_request do
      user nil
      external_user_name 'External User'
      external_url 'http://www.example.org/request/external'
    end

  end

end
