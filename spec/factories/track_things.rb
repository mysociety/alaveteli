# -*- encoding : utf-8 -*-
FactoryGirl.define do

    factory :track_thing do
        association :tracking_user, :factory => :user
        factory :search_track do
            track_medium 'email_daily'
            track_type 'search_query'
            track_query 'Example Query'
        end
        factory :user_track do
            association :tracked_user, :factory => :user
            track_type 'user_updates'
        end
        factory :public_body_track do
            association :public_body, :factory => :public_body
            track_type 'public_body_updates'
        end
        factory :request_update_track do
            association :info_request, :factory => :info_request
            track_type 'request_updates'
        end
        factory :successful_request_track do
            track_type 'all_successful_requests'
        end
        factory :new_request_track do
            track_type 'all_new_requests'
        end
    end

end
