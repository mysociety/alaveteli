FactoryGirl.define do
  factory :draft_info_request_batch, :class => AlaveteliPro::DraftInfoRequestBatch do
    user
    sequence(:title) { |n| "Draft: Example Title #{n}" }
    sequence(:body) { |n| "Do you have information about record #{n}?" }
    embargo_duration "3_months"
  end
end
