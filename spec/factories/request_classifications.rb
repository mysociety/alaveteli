# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: request_classifications
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  info_request_event_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

FactoryBot.define do

  factory :request_classification do
    user
    info_request_event
  end

end
