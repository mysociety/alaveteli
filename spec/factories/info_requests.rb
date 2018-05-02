# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_requests
#
#  id                                    :integer          not null, primary key
#  title                                 :text             not null
#  user_id                               :integer
#  public_body_id                        :integer          not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  described_state                       :string           not null
#  awaiting_description                  :boolean          default(FALSE), not null
#  prominence                            :string           default("normal"), not null
#  url_title                             :text             not null
#  law_used                              :string           default("foi"), not null
#  allow_new_responses_from              :string           default("anybody"), not null
#  handle_rejected_responses             :string           default("bounce"), not null
#  idhash                                :string           not null
#  external_user_name                    :string
#  external_url                          :string
#  attention_requested                   :boolean          default(FALSE)
#  comments_allowed                      :boolean          default(TRUE), not null
#  info_request_batch_id                 :integer
#  last_public_response_at               :datetime
#  reject_incoming_at_mta                :boolean          default(FALSE), not null
#  rejected_incoming_count               :integer          default(0)
#  date_initial_request_last_sent_at     :date
#  date_response_required_by             :date
#  date_very_overdue_after               :date
#  last_event_forming_initial_request_id :integer
#  use_notifications                     :boolean
#  last_event_time                       :datetime
#

FactoryGirl.define do

  factory :info_request do
    sequence(:title) { |n| "Example Title #{n}" }
    public_body
    user

    after(:create) do |info_request, evaluator|
      initial_request = create(:initial_request, :info_request => info_request,
                                                 :created_at => info_request.created_at)
      initial_request.last_sent_at = info_request.created_at
      initial_request.save
    end

    factory :info_request_with_incoming do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end

      factory :waiting_clarification_info_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('waiting_clarification')
        end
      end

      factory :successful_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('successful')
        end
      end

      factory :requires_admin_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('requires_admin')
        end
      end

      factory :error_message_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('error_message')
        end
      end

      factory :attention_requested_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('attention_requested')
        end
      end

      factory :not_held_request do
        after(:create) do |info_request, evaluator|
          info_request.set_described_state('not_held')
        end
      end

    end

    factory :info_request_with_plain_incoming do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:plain_incoming_message, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :info_request_with_html_attachment do
      after(:create) do |info_request, evaluator|
        incoming_message = create(:incoming_message_with_html_attachment, :info_request => info_request)
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

    factory :embargoed_request do
      after(:create) do |info_request, evaluator|
        create(:embargo, :info_request => info_request)
        info_request.reload
        incoming_message = create(:incoming_message_with_attachments, :info_request => info_request)
        info_request.log_event("response", {:incoming_message_id => incoming_message.id})
      end
    end

    factory :embargo_expiring_request do
      after(:create) do |info_request, evaluator|
        create(:expiring_embargo, :info_request => info_request)
        info_request.reload
      end
    end

    factory :re_embargoed_request do
      after(:create) do |info_request, evaluator|
        info_request.log_event('expire_embargo', {})
        create(:embargo, :info_request => info_request)
        info_request
      end
    end

    factory :embargo_expired_request do
      after(:create) do |info_request, evaluator|
        info_request.log_event("expire_embargo", info_request: info_request)
        info_request.reload
      end
    end

    factory :external_request do
      user nil
      external_user_name 'External User'
      external_url 'http://www.example.org/request/external'
    end

    factory :old_unclassified_request do
      after(:create) do |info_request, evaluator|
        incoming_message = FactoryGirl.create(
          :incoming_message,
          :info_request => info_request,
          :created_at => Time.zone.now - 31.days
        )
        info_request.info_request_events = [
          FactoryGirl.create(
            :info_request_event,
            :info_request => info_request,
            :event_type => "response",
            :incoming_message_id => incoming_message.id,
            :created_at => Time.zone.now - 31.days
          )
        ]
        info_request.last_public_response_at = Time.zone.now - 31.days
        info_request.awaiting_description = true
        info_request.save!
      end
    end

    factory :awaiting_description do
      awaiting_description true
      after(:create) do |info_request, evaluator|
        info_request.awaiting_description = true
        info_request.save!
      end
    end

    factory :hidden_request do
      prominence 'hidden'
    end

    factory :backpage_request do
      prominence 'backpage'
    end

    factory :overdue_request do
      date_response_required_by Time.zone.now - 1.day
      after(:create) do |info_request, evaluator|
        info_request.date_response_required_by = Time.zone.now - 1.day
        info_request.save!
      end
    end

    factory :very_overdue_request do
      date_response_required_by Time.zone.now - 21.days
      date_very_overdue_after Time.zone.now - 1.days
      after(:create) do |info_request, evaluator|
        info_request.date_response_required_by = Time.zone.now - 21.days
        info_request.date_very_overdue_after = Time.zone.now - 1.day
        info_request.save!
      end
    end

    factory :use_notifications_request do
      use_notifications true
    end
  end

end
