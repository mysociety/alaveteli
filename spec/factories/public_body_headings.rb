# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

FactoryGirl.define do
  factory :public_body_heading do
    sequence(:name) { |n| "Example Public Body Heading #{n}" }
  end
end
