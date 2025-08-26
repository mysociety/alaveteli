# == Schema Information
# Schema version: 20210114161442
#
# Table name: project_memberships
#
#  id         :bigint           not null, primary key
#  project_id :bigint
#  user_id    :bigint
#  role_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :project_membership, class: 'Project::Membership' do
    project
    user
    role
  end
end
