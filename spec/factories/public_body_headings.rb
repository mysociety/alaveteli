# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: public_body_headings
#
#  id                     :integer          not null, primary key
#  display_order          :integer
#  created_at             :datetime
#  updated_at             :datetime
#  public_body_heading_id :integer          not null
#  name                   :text
#

FactoryBot.define do
  factory :public_body_heading do
    sequence(:name) { |n| "Example Public Body Heading #{n}" }
  end
end
