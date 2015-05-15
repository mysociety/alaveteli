# -*- encoding : utf-8 -*-
FactoryGirl.define do

    factory :info_request_event do
        info_request
        event_type 'response'
        params_yaml ''
        factory :sent_event do
            event_type 'sent'
        end
    end

end
