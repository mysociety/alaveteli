# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: public_body_category_links
#
#  public_body_category_id :integer          not null
#  public_body_heading_id  :integer          not null
#  category_display_order  :integer
#  id                      :integer          not null, primary key
#  created_at              :datetime
#  updated_at              :datetime
#

FactoryBot.define do
  factory :public_body_category_link do
    association :public_body_category
    association :public_body_heading
  end
end
