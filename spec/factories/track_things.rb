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
#  track_medium     :string(255)      not null
#  track_type       :string(255)      default("internal_error"), not null
#  created_at       :datetime
#  updated_at       :datetime
#

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
