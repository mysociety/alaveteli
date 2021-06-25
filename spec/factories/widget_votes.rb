# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: widget_votes
#
#  id              :integer          not null, primary key
#  cookie          :string
#  info_request_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'securerandom'
FactoryBot.define do
  factory :widget_vote do
    info_request
    cookie { SecureRandom.hex(10) }
  end
end
