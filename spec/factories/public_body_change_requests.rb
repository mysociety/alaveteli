# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :public_body_change_request do
    user
    source_url 'http://www.example.com'
    notes 'Please'
    public_body_email 'new@example.com'
    factory :add_body_request do
      public_body_name 'A New Body'
    end
    factory :update_body_request do
      public_body
    end
  end

end
