require 'spec_helper'

RSpec.describe ProjectResource, type: :model, feature: :projects do
  subject(:project_resource) { FactoryBot.build_stubbed(:project_resource) }

  describe 'associations' do
    it 'belongs to a project' do
      expect(project_resource.project).to be_a Project
    end

    context 'when for an info request' do
      let(:project_resource) do
        FactoryBot.build_stubbed(:project_resource, :for_info_request)
      end

      it 'belongs to an info request via polymorphic resource' do
        expect(project_resource.resource).to be_a InfoRequest
      end
    end

    context 'when for an info request batch' do
      let(:project_resource) do
        FactoryBot.build_stubbed(:project_resource, :for_info_request_batch)
      end

      it 'belongs to an info request batch via polymorphic resource' do
        expect(project_resource.resource).to be_a InfoRequestBatch
      end
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires project' do
      project_resource.project = nil
      is_expected.not_to be_valid
    end

    it 'requires resource' do
      project_resource.resource = nil
      is_expected.not_to be_valid
    end
  end
end
