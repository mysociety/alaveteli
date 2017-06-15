# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :notification, aliases: [:instant_notification] do
    association :info_request_event, factory: :response_event
    user { info_request_event.info_request.user }
    frequency Notification::INSTANTLY

    factory :daily_notification do
      frequency Notification::DAILY
    end
  end
end
