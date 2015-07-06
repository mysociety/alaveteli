# -*- encoding : utf-8 -*-
FactoryGirl.define do
    factory :public_body_heading do
        sequence(:name) { |n| "Example Public Body Heading #{n}" }
    end
end
