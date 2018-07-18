# -*- encoding : utf-8 -*-
FactoryBot.define do
  factory :request_summary_category, :class => 'AlaveteliPro::RequestSummaryCategory',
                                     :aliases => [:waiting_response_request_summary_category] do
    slug 'waiting_response'
  end
end
