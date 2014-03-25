FactoryGirl.define do

    factory :track_thing do
        association :tracking_user, :factory => :user
        track_medium 'email_daily'
        track_type 'search_query'
        track_query 'Example Query'
    end

end
