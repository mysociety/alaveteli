# == Schema Information
#
# Table name: draft_info_requests
#
#  id               :integer          not null, primary key
#  title            :string
#  user_id          :integer
#  public_body_id   :integer
#  body             :text
#  embargo_duration :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :draft_info_request do
    sequence(:title) { |n| "Draft: Example Title #{n}" }
    public_body
    user
    sequence(:body) { |n| "Do you have information about record #{n}?" }
    embargo_duration { '3_months' }

    factory :draft_with_no_duration do
      embargo_duration nil
    end
  end
end
