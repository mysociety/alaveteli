# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_events
#
#  id                  :integer          not null, primary key
#  info_request_id     :integer          not null
#  event_type          :text             not null
#  params_yaml         :text             not null
#  created_at          :datetime         not null
#  described_state     :string(255)
#  calculated_state    :string(255)
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
#

FactoryGirl.define do

  factory :info_request_event do
    info_request
    event_type 'edit'
    params_yaml ''

    factory :sent_event do
      event_type 'sent'
      association :outgoing_message, :factory => :initial_request
    end

    factory :response_event do
      event_type 'response'
      incoming_message
    end

    factory :followup_sent_event do
      event_type 'followup_sent'
      association :outgoing_message, :factory => :new_information_followup
    end

    factory :comment_event do
      event_type 'comment'
      association :comment
    end

    factory :edit_event do
      event_type 'edit'
    end

    factory :hide_event do
      event_type 'hide'
    end

    factory :resent_event do
      event_type 'resent'
    end
  end

end
