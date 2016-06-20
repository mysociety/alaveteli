# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: widget_votes
#
#  id              :integer          not null, primary key
#  cookie          :string(255)
#  info_request_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'securerandom'
FactoryGirl.define do
  factory :widget_vote do
    info_request
    cookie { SecureRandom.hex(10) }
  end
end
