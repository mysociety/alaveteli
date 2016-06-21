# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#


FactoryGirl.define do
  factory :public_body_category do
    sequence(:title) { |n| "Example Public Body Category #{n}" }
    sequence(:category_tag) { |n| "example_tag_#{n}" }
    sequence(:description) { |n| "Example Public body Description #{n}" }
  end
end
