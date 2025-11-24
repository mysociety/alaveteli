# == Schema Information
# Schema version: 20220210114052
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  info_request_event_id :integer          not null
#  user_id               :integer          not null
#  frequency             :integer          default("instantly"), not null
#  seen_at               :datetime
#  send_after            :datetime         not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  expired               :boolean          default(FALSE)
#

FactoryBot.define do
  factory :notification, aliases: [:instant_notification] do
    association :info_request_event, factory: :response_event
    user { info_request_event.info_request.user }
    frequency { Notification::INSTANTLY }

    factory :daily_notification do
      frequency { Notification::DAILY }
    end
  end
end
