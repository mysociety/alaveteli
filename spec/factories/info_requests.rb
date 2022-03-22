# == Schema Information
# Schema version: 20220210114052
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
#  incoming_messages_count               :integer          default(0)
#  public_token                          :string
#

FactoryBot.define do

  factory :info_request do
    sequence(:title) { |n| "Example Title #{n}" }
    public_body
    user

    after(:create) do |info_request, evaluator|
      initial_request = create(:initial_request, :info_request => info_request,
                                                 :created_at => info_request.created_at)
      initial_request.last_sent_at = info_request.created_at
      initial_request.save!
    end

    trait :with_incoming do
      transient do
        incoming_message_factory { :incoming_message }
      end

      after(:create) do |info_request, evaluator|
        incoming_message = create(evaluator.incoming_message_factory,
                                  info_request: info_request)
        info_request.log_event("response",
                               { incoming_message_id: incoming_message.id })
      end
    end

    trait :with_plain_incoming do
      incoming_message_factory { :plain_incoming_message }
      with_incoming
    end

    trait :with_incoming_with_html_attachment do
      incoming_message_factory { :incoming_message_with_html_attachment }
      with_incoming
    end

    trait :with_incoming_with_attachments do
      incoming_message_factory { :incoming_message_with_attachments }
      with_incoming
    end

    trait :with_old_incoming do
      after(:create) do |info_request, _evaluator|
        incoming_message = FactoryBot.create(
          :incoming_message,
          info_request: info_request,
          created_at: Time.zone.now - 31.days
        )
        info_request.info_request_events = [
          FactoryBot.create(
            :info_request_event,
            info_request: info_request,
            event_type: "response",
            incoming_message_id: incoming_message.id,
            created_at: Time.zone.now - 31.days
          )
        ]
        info_request.last_public_response_at = Time.zone.now - 31.days
        info_request.save!
      end
    end

    trait :requires_admin do
      after(:create) do |info_request, _evaluator|
        info_request.log_event(
          'status_update',
          user_id: info_request.user.id,
          old_described_state: info_request.described_state,
          described_state: 'requires_admin',
          message: 'Useful info'
        )
        info_request.set_described_state('requires_admin')
      end
    end

    trait :error_message do
      after(:create) do |info_request, _evaluator|
        info_request.log_event(
          'status_update',
          user_id: info_request.user.id,
          old_described_state: info_request.described_state,
          described_state: 'error_message',
          message: 'Useful info'
        )
        info_request.set_described_state('error_message')
      end
    end

    trait :error_message_blank do
      after(:create) do |info_request, _evaluator|
        info_request.log_event(
          'status_update',
          user_id: info_request.user.id,
          old_described_state: info_request.described_state,
          described_state: 'error_message',
          message: ''
        )
        info_request.set_described_state('error_message')
      end
    end

    trait :attention_requested do
      after(:create) do |info_request, _evaluator|
        info_request.log_event('report_request',
                               request_id: info_request.id,
                               editor: info_request.user,
                               reason: 'Not a valid request',
                               message: 'Useful info',
                               old_attention_requested: false,
                               attention_requested: true)
        info_request.set_described_state('attention_requested')
      end
    end

    trait :with_internal_review_request do
      after(:create) do |info_request, evaluator|
        outgoing_message = create(:internal_review_request, :info_request => info_request)
      end
    end

    trait :embargoed do
      after(:create) do |info_request, evaluator|
        create(:embargo, :info_request => info_request)
        info_request.reload
      end
    end

    trait :embargo_expiring do
      after(:create) do |info_request, evaluator|
        create(:expiring_embargo, :info_request => info_request)
        info_request.reload
      end
    end

    trait :re_embargoed do
      after(:create) do |info_request, evaluator|
        info_request.log_event('expire_embargo', {})
        create(:embargo, :info_request => info_request)
        info_request
      end
    end

    trait :embargo_expired do
      after(:create) do |info_request, evaluator|
        info_request.log_event("expire_embargo", info_request: info_request)
        info_request.reload
      end
    end

    trait :awaiting_description do
      awaiting_description { true }
      after(:create) do |info_request, _evaluator|
        info_request.awaiting_description = true
        info_request.save!
      end
    end

    trait :external do
      user { nil }
      external_user_name { 'External User' }
      external_url { 'http://www.example.org/request/external' }
    end

    trait :hidden do
      prominence { 'hidden' }
    end

    trait :backpage do
      prominence { 'backpage' }
    end

    trait :waiting_clarification do
      after(:create) do |info_request, evaluator|
        info_request.set_described_state('waiting_clarification')
      end
    end

    trait :successful do
      after(:create) do |info_request, evaluator|
        info_request.set_described_state('successful')
      end
    end

    trait :partially_successful do
      after(:create) do |info_request, _evaluator|
        info_request.set_described_state('partially_successful')
      end
    end

    trait :refused do |_variable|
      after(:create) do |info_request, _evaluator|
        info_request.set_described_state('rejected')
      end
    end

    trait :not_held do
      after(:create) do |info_request, _evaluator|
        info_request.set_described_state('not_held')
      end
    end

    trait :overdue do
      date_response_required_by { Time.zone.now - 1.day }
      after(:create) do |info_request, evaluator|
        info_request.date_response_required_by = Time.zone.now - 1.day
        info_request.save!
      end
    end

    trait :very_overdue do
      date_response_required_by { Time.zone.now - 21.days }
      date_very_overdue_after { Time.zone.now - 1.days }
      after(:create) do |info_request, evaluator|
        info_request.date_response_required_by = Time.zone.now - 21.days
        info_request.date_very_overdue_after = Time.zone.now - 1.day
        info_request.save!
      end
    end

    trait :use_notifications do
      use_notifications { true }
    end

    factory :info_request_with_incoming, traits: [:with_incoming] do
      factory :waiting_clarification_info_request, traits: [:waiting_clarification]
      factory :successful_request, traits: [:successful]
      factory :requires_admin_request, traits: [:requires_admin]
      factory :error_message_request, traits: [:error_message]
      factory :blank_message_request, traits: [:error_message_blank]
      factory :attention_requested_request, traits: [:attention_requested]
      factory :not_held_request, traits: [:not_held]
    end

    factory :info_request_with_plain_incoming, traits: [:with_plain_incoming]
    factory :info_request_with_html_attachment, traits: [:with_incoming_with_html_attachment]
    factory :info_request_with_incoming_attachments, traits: [:with_incoming_with_attachments]
    factory :info_request_with_internal_review_request, traits: [:with_internal_review_request]
    factory :embargoed_request, traits: [:embargoed, :with_incoming_with_attachments]
    factory :embargo_expiring_request, traits: [:embargo_expiring]
    factory :re_embargoed_request, traits: [:re_embargoed]
    factory :embargo_expired_request, traits: [:embargo_expired]
    factory :external_request, traits: [:external]
    factory :old_unclassified_request, traits: [:with_old_incoming, :awaiting_description]
    factory :awaiting_description, traits: [:awaiting_description]
    factory :hidden_request, traits: [:hidden]
    factory :backpage_request, traits: [:backpage]
    factory :overdue_request, traits: [:overdue]
    factory :very_overdue_request, traits: [:very_overdue]
    factory :use_notifications_request, traits: [:use_notifications]
  end
end
