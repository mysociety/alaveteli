# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: public_body_categories
#
#  id                      :integer          not null, primary key
#  category_tag            :text             not null
#  created_at              :datetime
#  updated_at              :datetime
#  public_body_category_id :integer          not null
#  title                   :text
#  description             :text
#

FactoryBot.define do
  factory :public_body_category do
    sequence(:title) { |n| "Example Public Body Category #{n}" }
    sequence(:category_tag) { |n| "example_tag_#{n}" }
    sequence(:description) { |n| "Example Public body Description #{n}" }
  end
end
