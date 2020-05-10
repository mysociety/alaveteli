require 'spec_helper'

RSpec.describe Project::Submission, type: :model do
  subject(:submission) { FactoryBot.build(:project_submission) }

  describe 'associations' do
    it 'belongs to a project' do
      expect(submission.project).to be_a Project
    end

    it 'belongs to an user' do
      expect(submission.user).to be_an User
    end

    context 'when classification submission' do
      let(:submission) do
        FactoryBot.build(:project_submission, :for_classification)
      end

      it 'belongs to a info request event via polymorphic resource' do
        expect(submission.resource).to be_a InfoRequestEvent
      end
    end

    context 'when dataset value set submission' do
      let(:submission) do
        FactoryBot.build(:project_submission, :for_extraction)
      end

      it 'belongs to a dataset value set via polymorphic resource' do
        expect(submission.resource).to be_a Dataset::ValueSet
      end
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires project' do
      submission.project = nil
      is_expected.not_to be_valid
    end

    it 'requires user' do
      submission.user = nil
      is_expected.not_to be_valid
    end

    it 'requires resource' do
      submission.resource = nil
      is_expected.not_to be_valid
    end

    it 'requires resource to be a Classification or Dataset::ValueSet' do
      submission.resource = FactoryBot.build(:user)
      is_expected.not_to be_valid
      submission.resource = FactoryBot.build(:status_update_event)
      is_expected.to be_valid
      submission.resource = FactoryBot.build(:dataset_value_set)
      is_expected.to be_valid
    end
  end
end
