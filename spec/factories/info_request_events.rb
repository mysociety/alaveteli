# == Schema Information
# Schema version: 20220408125559
#
# Table name: info_request_events
#
#  id                  :integer          not null, primary key
#  info_request_id     :integer          not null
#  event_type          :text             not null
#  params_yaml         :text             not null
#  created_at          :datetime         not null
#  described_state     :string
#  calculated_state    :string
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
#  updated_at          :datetime
#  params              :jsonb
#

FactoryBot.define do

  factory :info_request_event do
    info_request
    event_type { 'edit' }
    params { {} }

    factory :sent_event do
      event_type { 'sent' }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :initial_request, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end
    end

    factory :failed_sent_request_event do
      event_type { 'send_error' }
      params { { reason: 'Connection timed out' } }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :initial_request, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end

      after(:create) do |evnt, evaluator|
        evnt.params = evnt.params.merge(
          outgoing_message_id: evnt.outgoing_message.id
        )
        evnt.outgoing_message.status = 'failed'
        evnt.info_request.described_state = 'error_message'
      end
    end

    factory :response_event do
      transient do
        incoming_message_factory { :incoming_message }
      end

      event_type { 'response' }

      after(:build) do |event, evaluator|
        event.incoming_message ||= build(
          evaluator.incoming_message_factory, info_request: event.info_request
        )
        event.info_request = event.incoming_message.info_request
      end

      trait :with_attachments do
        incoming_message_factory { :incoming_message_with_attachments }
      end
    end

    factory :followup_sent_event do
      event_type { 'followup_sent' }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :new_information_followup, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end
    end

    factory :followup_resent_event do
      event_type { 'followup_resent' }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :new_information_followup, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end
    end

    factory :failed_sent_followup_event do
      event_type { 'send_error' }
      params { { reason: 'Connection timed out' } }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :new_information_followup, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end

      after(:create) do |evnt, evaluator|
        evnt.params = evnt.params.merge(
          outgoing_message_id: evnt.outgoing_message.id
        )
        evnt.outgoing_message.status = 'failed'
        evnt.info_request.described_state = 'error_message'
      end
    end

    factory :comment_event do
      event_type { 'comment' }

      after(:build) do |event|
        event.comment ||= build(:comment, info_request: event.info_request)
        event.info_request = event.comment.info_request
      end
    end

    factory :edit_event do
      event_type { 'edit' }
    end

    factory :hide_event do
      event_type { 'hide' }
    end

    factory :resent_event do
      event_type { 'resent' }

      after(:build) do |event|
        event.outgoing_message ||= build(
          :initial_request, info_request: event.info_request
        )
        event.info_request = event.outgoing_message.info_request
      end
    end

    factory :overdue_event do
      event_type { 'overdue' }
    end

    factory :very_overdue_event do
      event_type { 'very_overdue' }
    end

    factory :expire_embargo_event do
      event_type { 'expire_embargo' }
    end

    factory :embargo_expiring_event do
      event_type { 'embargo_expiring' }
    end

    factory :status_update_event do
      event_type { 'status_update' }
    end

    factory :refusal_advice_event do
      event_type { 'refusal_advice' }
      params do
        {
          questions: {
            exemption: 'section-12', question_1: 'no', question_2: 'yes'
          },
          actions: {
            action_1: { suggestion_1: false, suggestion_2: true },
            action_2: { suggestion_3: true, suggestion_4: false },
            action_3: { suggestion_5: false }
          },
          id: 'action_2'
        }
      end

      after(:build) do |event|
        event.params = event.params.merge(
          user_id: event.info_request.user.id
        )
      end
    end

  end

end
