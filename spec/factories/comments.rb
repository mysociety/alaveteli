# == Schema Information
# Schema version: 20220210114052
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

FactoryBot.define do

  factory :comment do
    user
    info_request

    body { 'This a wise and helpful annotation.' }

    factory :visible_comment do
      visible { true }
    end

    factory :hidden_comment do
      visible { false }
    end

    factory :attention_requested_comment do
      transient do
        message { nil }
        reason { nil }
      end

      after(:create) do |comment, evaluator|
        reporting_user = create(:user)
        reason = evaluator.reason || comment.report_reasons.sample
        user_message = evaluator.message || 'Bad Comment'
        comment.report!(reason, user_message, reporting_user)
      end
    end

    factory :embargoed_comment do
      association :info_request, factory: :embargoed_request
    end

    trait :with_event do
      after(:create) do |comment, _|
        comment.info_request.log_event('comment', comment_id: comment.id)
      end
    end
  end

end
