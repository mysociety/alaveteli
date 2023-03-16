require 'spec_helper'

RSpec.describe Project::Leaderboard do
  let(:project) { instance_double('Project') }
  let(:instance) { described_class.new(project) }

  shared_context 'project submissions' do
    let(:project) { FactoryBot.create(:project, contributors_count: 2) }
    let(:user_1) { project.members[1] } # member 0 is the project owner
    let(:user_2) { project.members[2] }

    before do
      FactoryBot.create(
        :project_submission, :for_classification, project: project, user: user_1
      )
      FactoryBot.create(
        :project_submission, :for_extraction, project: project, user: user_1
      )

      travel_to 28.days.ago
      FactoryBot.create(
        :project_submission, :for_extraction, project: project, user: user_2
      )
      travel_back
    end
  end

  describe '#all_time' do
    include_context 'project submissions'

    subject(:data) { instance.all_time }

    it 'returns the data that we would expect' do
      is_expected.to include(
        classifications: 1, extractions: 1, total_contributions: 2, user: user_1
      )
      is_expected.to include(
        classifications: 0, extractions: 1, total_contributions: 1, user: user_2
      )
    end

    it 'orders the data by descending total contributions' do
      expect(data[0][:total_contributions]).to eq(2)
      expect(data[1][:total_contributions]).to eq(1)
      expect(data[2][:total_contributions]).to eq(0)
    end

    context 'when project has more than 5 members' do
      let(:project) { FactoryBot.create(:project, contributors_count: 10) }

      it 'returns a maximum of 5 rows' do
        expect(data.count).to eq(5)
      end
    end
  end

  describe '#twenty_eight_days' do
    include_context 'project submissions'

    subject(:data) { instance.twenty_eight_days }

    it 'returns the data that we would expect from the last 28 days' do
      is_expected.to include(
        classifications: 1, extractions: 1, total_contributions: 2, user: user_1
      )
      is_expected.to include(
        classifications: 0, extractions: 0, total_contributions: 0, user: user_2
      )
    end

    it 'orders the data by descending total contributions' do
      expect(data[0][:total_contributions]).to eq(2)
      expect(data[1][:total_contributions]).to eq(0)
    end

    context 'when project has more than 5 members' do
      let(:project) { FactoryBot.create(:project, contributors_count: 10) }

      it 'returns a maximum of 5 rows' do
        expect(data.count).to eq(5)
      end
    end
  end

  describe '#name' do
    let(:project) { instance_double('Project', id: 1, title: 'Test Project') }
    subject { instance.name }

    it 'returns a useful filename' do
      travel_to Time.utc(2019, 11, 18, 10, 30)
      is_expected.to(
        eq 'project-leaderboard-1-test_project-2019-11-18-103000.csv'
      )
      travel_back
    end
  end

  describe '#to_csv' do
    subject { instance.to_csv }

    let(:user) { instance_double('User', name: 'Bob') }

    it 'returns CSV string from leaderboard' do
      allow(instance).to receive(:data).and_return(
        [{ foo: 'Foo', bar: 'Bar', user: user }]
      )

      is_expected.to eq <<~CSV
        foo,bar,user
        Foo,Bar,Bob
      CSV
    end
  end
end
