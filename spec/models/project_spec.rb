require 'spec_helper'

RSpec.describe Project, type: :model, feature: :projects do
  subject(:project) { FactoryBot.build_stubbed(:project) }

  describe 'associations' do
    subject(:project) do
      FactoryBot.create(
        :project,
        owner: owner,
        contributors_count: 2, requests_count: 2, batches_count: 2
      )
    end

    let(:owner) { FactoryBot.build(:pro_user) }

    it 'has many members' do
      expect(project.members).to all be_a(User)
      expect(project.members).to include(owner)
      expect(project.members.count).to eq 3
    end

    it 'has one owner' do
      expect(project.owner).to be_a User
      expect(project.owner).to eq owner
    end

    it 'has many contributors' do
      expect(project.contributors).to all be_a(User)
      expect(project.contributors).not_to include owner
      expect(project.contributors.count).to eq 2
    end

    it 'has many resources' do
      expect(project.resources).to all be_a(ProjectResource)
      expect(project.resources.count).to eq 4
    end

    it 'has many requests' do
      expect(project.requests).to all be_a(InfoRequest)
      expect(project.requests.count).to eq 2
    end

    it 'has many contributors' do
      expect(project.batches).to all be_a(InfoRequestBatch)
      expect(project.batches.count).to eq 2
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires title' do
      project.title = nil
      is_expected.not_to be_valid
    end

    it 'requires owner' do
      project.owner = nil
      is_expected.not_to be_valid
    end
  end

  describe '#info_requests' do
    let(:project) do
      FactoryBot.create(:project, requests: [request], batches: [batch])
    end

    let(:request) { FactoryBot.build(:info_request) }
    let(:batch) { FactoryBot.build(:info_request_batch, :sent) }

    let!(:other_request) { FactoryBot.create(:info_request) }
    let!(:other_batch) { FactoryBot.create(:info_request_batch, :sent) }

    subject { project.info_requests }

    it 'returns array of InfoRequest' do
      is_expected.to all be_an(InfoRequest)
    end

    it 'includes requests' do
      is_expected.to include request
    end

    it 'excludes other requests' do
      is_expected.not_to include other_request
    end

    it 'includes batch requests' do
      is_expected.to include(*batch.info_requests)
    end

    it 'excludes other batch requests' do
      is_expected.not_to include(*other_batch.info_requests)
    end
  end
end
