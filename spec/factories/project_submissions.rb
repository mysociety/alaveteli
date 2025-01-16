# == Schema Information
# Schema version: 20210114161442
#
# Table name: project_submissions
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  user_id         :integer
#  resource_type   :string
#  resource_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  info_request_id :integer
#

FactoryBot.define do
  factory :project_submission, class: 'Project::Submission' do
    project
    user
    info_request

    for_classification

    trait :for_classification do
      association :resource, factory: :status_update_event
    end

    trait :for_extraction do
      association :resource, factory: :dataset_value_set
    end
  end
end
