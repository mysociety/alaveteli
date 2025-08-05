# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: track_things
#
#  id               :integer          not null, primary key
#  tracking_user_id :integer          not null
#  track_query      :string(500)      not null
#  info_request_id  :integer
#  tracked_user_id  :integer
#  public_body_id   :integer
#  track_medium     :string           not null
#  track_type       :string           default("internal_error"), not null
#  created_at       :datetime
#  updated_at       :datetime
#

FactoryBot.define do

  factory :track_thing do
    track_medium { 'email_daily' }
    track_query { 'Example Query' }
    track_type { 'search_query' }
    association :tracking_user, :factory => :user
    factory :search_track
    factory :user_track do
      association :tracked_user, :factory => :user
      track_type { 'user_updates' }
      after(:create) do |track_thing, evaluator|
        track_thing.track_query = "requested_by:#{ user.url_name }" \
                                  " OR commented_by: #{ user.url_name }"
        track_thing.save
      end
    end
    factory :public_body_track do
      association :public_body, :factory => :public_body
      track_type { 'public_body_updates' }
      after(:create) do |track_thing, evaluator|
        track_thing.track_query = "requested_from:" \
                                  "#{ track_thing.public_body.url_name }"
        track_thing.save
      end
    end
    factory :request_update_track do
      association :info_request, :factory => :info_request
      track_type { 'request_updates' }
      after(:create) do |track_thing, evaluator|
        track_thing.track_query = "request:" \
                                  "#{ track_thing.info_request.url_title }"
        track_thing.save
      end
    end
    factory :successful_request_track do
      track_type { 'all_successful_requests' }
      track_query do
        'variety:response ' \
        '(status:successful OR status:partially_successful)'
      end
    end
    factory :new_request_track do
      track_type { 'all_new_requests' }
      track_query { 'variety:sent' }
    end
  end

end
