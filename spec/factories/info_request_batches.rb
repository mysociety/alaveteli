# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :info_request_batch do
    title "Example title"
    user
    body "Some text"
  end

end
