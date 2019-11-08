# == Schema Information
# Schema version: 20220322100510
#
# Table name: draft_info_request_batches
#
#  id               :bigint           not null, primary key
#  title            :string
#  body             :text
#  user_id          :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string
#

FactoryBot.define do
  factory :draft_info_request_batch, :class => AlaveteliPro::DraftInfoRequestBatch do
    user
    sequence(:title) { |n| "Draft: Example Title #{n}" }
    sequence(:body) { |n| "Do you have information about record #{n}?" }
    embargo_duration { '3_months' }
  end
end
