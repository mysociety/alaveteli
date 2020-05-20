# == Schema Information
# Schema version: 20200520073810
#
# Table name: project_memberships
#
#  id         :integer          not null, primary key
#  project_id :integer
#  user_id    :integer
#  role_id    :integer
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
