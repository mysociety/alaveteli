# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :censor_rule do
    text 'some text to redact'
    replacement '[REDACTED]'
    last_edit_editor 'FactoryGirl'
    last_edit_comment 'Modified by rspec'

    factory :regexp_censor_rule do
      text '\w+@\w+'
      regexp true
    end

    factory :info_request_censor_rule do
      info_request
    end

    factory :public_body_censor_rule do
      public_body
    end

    factory :user_censor_rule do
      user
    end

    factory :global_censor_rule do
      initialize_with { CensorRule.new(:allow_global => true) }
    end

  end

end
