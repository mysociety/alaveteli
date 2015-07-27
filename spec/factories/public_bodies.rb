# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :public_body do
    sequence(:name) { |n| "Example Public Body #{n}" }
    sequence(:short_name) { |n| "Example Body #{n}" }
    request_email 'request@example.com'
    last_edit_editor "admin user"
    last_edit_comment "Making an edit"
  end


end
