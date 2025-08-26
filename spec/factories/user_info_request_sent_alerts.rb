# == Schema Information
#
# Table name: user_info_request_sent_alerts
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  info_request_id       :integer          not null
#  alert_type            :string           not null
#  info_request_event_id :integer
#  created_at            :datetime
#  updated_at            :datetime
#

FactoryBot.define do
  factory :user_info_request_sent_alert do
    user
    info_request
    info_request_event

    alert_type { 'overdue_1' }
  end
end
