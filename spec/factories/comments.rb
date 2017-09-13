# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: comments
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  info_request_id     :integer
#  body                :text             not null
#  visible             :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  locale              :text             default(""), not null
#  attention_requested :boolean          default(FALSE), not null
#

FactoryGirl.define do

  factory :comment do
    user
    info_request

    body 'This a wise and helpful annotation.'

    factory :visible_comment do
      visible true
    end

    factory :hidden_comment do
      visible false
    end

    factory :attention_requested do
      after(:create) do |comment, evaluator|
        reporting_user = create(:user)
        reason = comment.report_reasons.sample
        comment.report!(reason, 'Bad Comment', reporting_user)
      end
    end

    factory :embargoed_comment do
      association :info_request, factory: :embargoed_request
    end
  end

end
