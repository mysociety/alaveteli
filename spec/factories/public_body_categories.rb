# -*- encoding : utf-8 -*-

FactoryGirl.define do
  factory :public_body_category do
    sequence(:title) { |n| "Example Public Body Category #{n}" }
    sequence(:category_tag) { |n| "example_tag_#{n}" }
    sequence(:description) { |n| "Example Public body Description #{n}" }
  end
end
