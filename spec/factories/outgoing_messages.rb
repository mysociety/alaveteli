# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :outgoing_message do
    info_request

    factory :initial_request do
      ignore do
        status 'ready'
        message_type 'initial_request'
        body 'Some information please'
        what_doing 'normal_sort'
      end

    end

    factory :internal_review_request do
      ignore do
        status 'ready'
        message_type 'followup'
        body 'I want a review'
        what_doing 'internal_review'
      end

    end

    # FIXME: This here because OutgoingMessage has an after_initialize,
    # which seems to call everything in the app! FactoryGirl calls new with
    # no parameters and then uses the assignment operator of each attribute
    # to update it. Because after_initialize executes before assigning the
    # attributes, loads of stuff fails because whatever after_initialize is
    # doing expects some of the attributes to be there.
    initialize_with { OutgoingMessage.new({ :status => status,
                                            :message_type => message_type,
                                            :body => body,
                                            :what_doing => what_doing }) }

    after_create do |outgoing_message|
      outgoing_message.sendable?
      outgoing_message.record_email_delivery(
        'test@example.com',
      'ogm-14+537f69734b97c-1ebd@localhost')
    end

  end

end
