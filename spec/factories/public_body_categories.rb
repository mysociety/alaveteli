# == Schema Information
# Schema version: 20220322100510
#
# Table name: public_body_categories
#
#  id           :bigint           not null, primary key
#  category_tag :text             not null
#  created_at   :datetime
#  updated_at   :datetime
#  title        :text
#  description  :text
#

FactoryBot.define do
  factory :public_body_category do
    sequence(:title) { |n| "Example Public Body Category #{n}" }
    sequence(:category_tag) { |n| "example_tag_#{n}" }
    sequence(:description) { |n| "Example Public body Description #{n}" }
  end
end
