require 'spec_helper'

RSpec.describe Dataset::KeySet, type: :model do
  subject(:key_set) { FactoryBot.build(:dataset_key_set) }

  describe 'associations' do
    subject(:key_set) do
      FactoryBot.create(:dataset_key_set, key_count: 2, value_set_count: 2)
    end

    context 'when project key set' do
      let(:key_set) { FactoryBot.build(:dataset_key_set, :for_project) }

      it 'belongs to a project via polymorphic resource' do
        expect(key_set.resource).to be_a Project
      end
    end

    context 'when info request key set' do
      let(:key_set) { FactoryBot.build(:dataset_key_set, :for_info_request) }

      it 'belongs to a info request via polymorphic resource' do
        expect(key_set.resource).to be_a InfoRequest
      end
    end

    context 'when info request batch key set' do
      let(:key_set) do
        FactoryBot.build(:dataset_key_set, :for_info_request_batch)
      end

      it 'belongs to a info request batch via polymorphic resource' do
        expect(key_set.resource).to be_a InfoRequestBatch
      end
    end

    it 'has many keys' do
      expect(key_set.keys).to all be_a(Dataset::Key)
      expect(key_set.keys.count).to eq 2
    end

    it 'has many value sets' do
      expect(key_set.value_sets).to all be_a(Dataset::ValueSet)
      expect(key_set.value_sets.count).to eq 2
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires resource' do
      key_set.resource = nil
      is_expected.not_to be_valid
    end

    it 'requires resource to be a Project, InfoRequest or InfoRequestBatch' do
      key_set.resource = FactoryBot.build(:user)
      is_expected.not_to be_valid
      key_set.resource = FactoryBot.build(:project)
      is_expected.to be_valid
      key_set.resource = FactoryBot.build(:info_request)
      is_expected.to be_valid
      key_set.resource = FactoryBot.build(:info_request_batch)
      is_expected.to be_valid
    end
  end
end
