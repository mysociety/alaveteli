FactoryGirl.define do

    factory :outgoing_message do
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
        initialize_with { OutgoingMessage.new({ :status => status,
                                                :message_type => message_type,
                                                :body => body,
                                                :what_doing => what_doing }) }
        after_create do |outgoing_message|
            outgoing_message.send_message
        end
    end
    
end
