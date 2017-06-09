# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20170411113908
#
# Table name: request_summaries
#
#  id                :integer          not null, primary key
#  title             :text
#  body              :text
#  public_body_names :text
#  summarisable_id   :integer
#  summarisable_type :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

FactoryGirl.define do
  factory :request_summary, :class => AlaveteliPro::RequestSummary do
    sequence(:title) { |n| "Example Title #{n}" }
    sequence(:body) { |n| "Example request #{n}" }
    public_body_names "Example Public Body"
    association :summarisable , :factory => :info_request
    user :factory => :pro_user

    before(:create) do |summary, evaluator|
      # Creating the info_request has the side effect of creating a request
      # summary automatically, but we want to return the one we've just made
      summary.summarisable.request_summary.destroy
      summary.summarisable.request_summary = summary
    end

    factory :draft_request_summary do
      association :summarisable , :factory => :draft_info_request
    end

    factory :batch_request_summary do
      association :summarisable , :factory => :info_request_batch
    end

    factory :draft_batch_request_summary do
      association :summarisable , :factory => :draft_info_request_batch
    end
  end
end
