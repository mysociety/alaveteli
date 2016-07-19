# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_requests
#
#  id                        :integer          not null, primary key
#  title                     :text             not null
#  user_id                   :integer
#  public_body_id            :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  described_state           :string(255)      not null
#  awaiting_description      :boolean          default(FALSE), not null
#  prominence                :string(255)      default("normal"), not null
#  url_title                 :text             not null
#  law_used                  :string(255)      default("foi"), not null
#  allow_new_responses_from  :string(255)      default("anybody"), not null
#  handle_rejected_responses :string(255)      default("bounce"), not null
#  idhash                    :string(255)      not null
#  external_user_name        :string(255)
#  external_url              :string(255)
#  attention_requested       :boolean          default(FALSE)
#  comments_allowed          :boolean          default(TRUE), not null
#  info_request_batch_id     :integer
#  last_public_response_at   :datetime
#  reject_incoming_at_mta    :boolean          default(FALSE), not null
#  rejected_incoming_count   :integer          default(0)
#

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

    factory :old_unclassified_request do
      after(:create) do |info_request, evaluator|
        incoming_message = FactoryGirl.create(:incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
        info_request.last_public_response_at = Time.now - 31.days
        info_request.awaiting_description = true
        info_request.save!
      end
    end
  end

end
