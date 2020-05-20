# == Schema Information
# Schema version: 20200520073810
#
# Table name: project_resources
#
#  id            :integer          not null, primary key
#  project_id    :integer
#  resource_type :string
#  resource_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :project_resource, class: 'Project::Resource' do
    project
    association :resource, factory: :info_request

    trait :for_info_request do
      association :resource, factory: :info_request
    end

    trait :for_info_request_batch do
      association :resource, factory: :info_request_batch
    end
  end
end
