# == Schema Information
#
# Table name: project_submissions
#
#  id              :bigint           not null, primary key
#  project_id      :bigint
#  user_id         :bigint
#  resource_type   :string
#  resource_id     :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  info_request_id :bigint
#  parent_id       :bigint
#  current         :boolean          default(TRUE), not null
#

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

    it 'belongs to an info request' do
      expect(submission.info_request).to be_an InfoRequest
    end

    it 'optionally belongs to a parent submission' do
      parent = FactoryBot.create(:project_submission)
      child = FactoryBot.build(:project_submission, parent: parent)
      expect(child.parent).to eq(parent)
    end

    it 'has many versions' do
      parent = FactoryBot.create(:project_submission)
      version1 = FactoryBot.create(:project_submission, parent: parent)
      version2 = FactoryBot.create(:project_submission, parent: parent)

      expect(parent.versions).to include(version1, version2)
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

  describe 'scopes' do
    let!(:classification) do
      FactoryBot.create(:project_submission, :for_classification)
    end

    let!(:extraction) do
      FactoryBot.create(:project_submission, :for_extraction)
    end

    let!(:historical_submission) do
      FactoryBot.create(:project_submission, current: false)
    end

    let!(:current_submission) do
      FactoryBot.create(:project_submission, current: true)
    end

    it 'can scope to classification submissions' do
      expect(described_class.classification).to match_array([
        classification, historical_submission, current_submission
      ])
    end

    it 'can scope to extraction submissions' do
      expect(described_class.extraction).to match_array([extraction])
    end

    it 'can scope to current submissions' do
      expect(described_class.current).to include(classification, extraction, current_submission)
      expect(described_class.current).not_to include(historical_submission)
    end

    it 'can scope to historical submissions' do
      expect(described_class.historical).to include(historical_submission)
      expect(described_class.historical).not_to include(classification, extraction, current_submission)
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

    it 'requires info request' do
      submission.info_request = nil
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

  describe 'versioning methods' do
    let(:original) { FactoryBot.create(:project_submission) }
    let(:version1) { FactoryBot.create(:project_submission, parent: original) }
    let(:version2) { FactoryBot.create(:project_submission, parent: original) }

    describe '#original_submission' do
      it 'returns self for original submission' do
        expect(original.original_submission).to eq(original)
      end

      it 'returns parent for versioned submission' do
        expect(version1.original_submission).to eq(original)
      end
    end

    describe '#create_new_version' do
      let(:editor) { FactoryBot.create(:user) }
      let(:new_resource) { FactoryBot.create(:status_update_event) }

      it 'creates a new version with correct attributes' do
        new_version = original.create_new_version(
          user: editor,
          resource: new_resource
        )

        expect(new_version).to be_persisted
        expect(new_version.parent).to eq(original)
        expect(new_version.user).to eq(editor)
        expect(new_version.resource).to eq(new_resource)
        expect(new_version.current).to be true
      end

      it 'marks previous versions as not current' do
        version1.update!(current: true)
        original.create_new_version(
          user: editor, resource: new_resource
        )
        expect(version1.reload.current).to be false
      end
    end
  end
end
