# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: raw_emails
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

FactoryBot.define do
  factory :raw_email
end
