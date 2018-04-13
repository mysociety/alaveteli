# -*- encoding : utf-8 -*-
# == Schema Information
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

FactoryGirl.define do
  factory :public_body_category_link do
    association :public_body_category
    association :public_body_heading
  end
end
