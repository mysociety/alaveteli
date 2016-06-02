# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  info_request_id   :integer
#  user_id           :integer
#  public_body_id    :integer
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string(255)      not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean
#

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
    end

  end

end
