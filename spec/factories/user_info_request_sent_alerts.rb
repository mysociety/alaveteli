# == Schema Information
# Schema version: 20220322100510
#
# Table name: user_info_request_sent_alerts
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint           not null
#  info_request_id       :bigint           not null
#  alert_type            :string           not null
#  info_request_event_id :bigint
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
