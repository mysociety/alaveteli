# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: outgoing_messages
#
#  id                           :integer          not null, primary key
#  info_request_id              :integer          not null
#  body                         :text             not null
#  status                       :string           not null
#  message_type                 :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  last_sent_at                 :datetime
#  incoming_message_followup_id :integer
#  what_doing                   :string           not null
#  prominence                   :string           default("normal"), not null
#  prominence_reason            :text
#

FactoryBot.define do

  factory :outgoing_message do
    info_request
    prominence { 'normal' }
    last_sent_at { 2.weeks.ago }

    factory :initial_request do
      transient do
        status { 'ready' }
        message_type { 'initial_request' }
        body { 'Some information please' }
        what_doing { 'normal_sort' }
        prominence { 'normal' }
      end
    end

    factory :new_information_followup do
      transient do
        status { 'ready' }
        message_type { 'followup' }
        body { 'I clarify my request' }
        what_doing { 'new_information' }
        prominence { 'normal' }
      end
    end

    factory :internal_review_request do
      transient do
        status { 'ready' }
        message_type { 'followup' }
        body { 'I want a review' }
        what_doing { 'internal_review' }
        prominence { 'normal' }
      end
    end

    factory :hidden_followup do
      transient do
        status { 'ready' }
        message_type { 'followup' }
        body { 'I clarify my request' }
        what_doing { 'new_information' }
        prominence { 'hidden' }
      end
    end

    # FIXME: This here because OutgoingMessage has an after_initialize,
    # which seems to call everything in the app! FactoryBot calls new with
    # no parameters and then uses the assignment operator of each attribute
    # to update it. Because after_initialize executes before assigning the
    # attributes, loads of stuff fails because whatever after_initialize is
    # doing expects some of the attributes to be there.
    initialize_with { OutgoingMessage.new({ :status => status,
                                            :message_type => message_type,
                                            :body => body,
                                            :what_doing => what_doing,
                                            :prominence => prominence }) }

    after(:create) do |outgoing_message|
      outgoing_message.sendable?
      outgoing_message.record_email_delivery(
        'test@example.com',
      'ogm-14+537f69734b97c-1ebd@localhost')
    end

  end

end
