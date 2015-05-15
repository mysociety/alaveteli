# -*- encoding : utf-8 -*-
FactoryGirl.define do
    factory :public_body_category_link do
        association :public_body_category
        association :public_body_heading
    end
end
