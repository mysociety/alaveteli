FactoryBot.define do
  factory :project_membership, class: 'Project::Membership' do
    project
    user
    role
  end
end
