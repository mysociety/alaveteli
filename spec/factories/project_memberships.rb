FactoryBot.define do
  factory :project_membership do
    project
    user
    role
  end
end
