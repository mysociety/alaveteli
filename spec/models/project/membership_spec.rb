# == Schema Information
# Schema version: 20210114161442
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

require 'spec_helper'

RSpec.describe Project::Membership, type: :model, feature: :projects do
  subject(:project_membership) { FactoryBot.build_stubbed(:project_membership) }

  describe 'associations' do
    it 'belongs to a project' do
      expect(project_membership.project).to be_a Project
    end

    it 'belongs to a user' do
      expect(project_membership.user).to be_a User
    end

    it 'belongs to a role' do
      expect(project_membership.role).to be_a Role
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires project' do
      project_membership.project = nil
      is_expected.not_to be_valid
    end

    it 'requires user' do
      project_membership.user = nil
      is_expected.not_to be_valid
    end

    it 'requires role' do
      project_membership.role = nil
      is_expected.not_to be_valid
    end
  end
end
