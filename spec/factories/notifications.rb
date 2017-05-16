# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :notification, aliases: [:instant_notification] do
    association :info_request_event, factory: :response_event
    user { info_request_event.info_request.user }
    frequency Notification::INSTANTLY
    send_after { Time.zone.now }

    factory :daily_notification do
      frequency Notification::DAILY
      send_after { Time.zone.tomorrow.beginning_of_day }
    end
  end
end
