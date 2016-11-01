# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: embargos
#
#  id              :integer          not null, primary key
#  info_request_id :integer          not null
#  publish_at      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryGirl.define do
  factory :embargo do
    info_request
    publish_at Time.now + 3.months
  end
end
