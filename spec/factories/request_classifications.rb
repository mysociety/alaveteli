# == Schema Information
# Schema version: 20220322100510
#
# Table name: request_classifications
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint
#  info_request_event_id :bigint
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

FactoryBot.define do

  factory :request_classification do
    user
    info_request_event
  end

end
