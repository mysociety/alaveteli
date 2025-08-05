# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_batches
#
#  id               :integer          not null, primary key
#  title            :text             not null
#  user_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  sent_at          :datetime
#  embargo_duration :string
#

FactoryBot.define do

  factory :info_request_batch do
    title { 'Example title' }
    user
    body { 'Some text' }

    # NB order of the traits is important as the after callbacks are run in the
    # order the traits are defined.

    trait :embargoed do
      embargo_duration { '3_months' }

      after(:build) do |batch, evaluator|
        batch.info_requests.each do |request|
          request.embargo = build(:embargo)
        end
      end
    end

    trait :sent do
      transient do
        public_body_count { 1 }
      end

      after(:build) do |batch, evaluator|
        factory = batch.embargo_duration ? :embargoed_request : :info_request
        batch.info_requests = build_list(factory, evaluator.public_body_count,
                                         user: batch.user)

        batch.info_requests.each do |request|
          request.info_request_events = [
            build(:sent_event, info_request: request)
          ]
        end

        batch.public_bodies = batch.info_requests.map(&:public_body)
        batch.sent_at = Time.zone.now
      end
    end
  end
end
