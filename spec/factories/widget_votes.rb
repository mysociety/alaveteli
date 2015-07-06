# -*- encoding : utf-8 -*-
require 'securerandom'
FactoryGirl.define do
  factory :widget_vote do
    info_request
    cookie { SecureRandom.hex(10) }
  end
end
