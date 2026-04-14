require 'spec_helper'

RSpec.describe Project::Export do
  let(:project) { instance_double('Project') }
  let(:instance) { described_class.new(project, user: user) }
  let(:user) { nil }

  describe '#data' do
    subject { instance.data }

    let(:info_request_a) { instance_double('InfoRequest') }
    let(:info_request_b) { instance_double('InfoRequest') }

    before do
      allow(instance).to receive(:visible_requests).
        and_return([info_request_a, info_request_b])
    end

    it 'individually exports info requests' do
      expect(Project::Export::InfoRequest).to receive(:new).
        with(project, info_request_a).
        and_return(double(data: { header: 'DATA A' }))
      expect(Project::Export::InfoRequest).to receive(:new).
        with(project, info_request_b).
        and_return(double(data: { header: 'DATA B' }))

      is_expected.to match_array [{ header: 'DATA A' }, { header: 'DATA B' }]
    end
  end

  describe 'requester_only filtering', feature: :projects do
    let(:owner) { FactoryBot.create(:pro_user) }
    let(:project) { FactoryBot.create(:project, owner: owner) }
    let(:normal_request) { FactoryBot.create(:successful_request) }
    let(:requester_only_request) do
      FactoryBot.create(:successful_request, prominence: 'requester_only')
    end

    before do
      project.requests << [normal_request, requester_only_request]
    end

    context 'when user is the project owner' do
      let(:user) { owner }

      it 'excludes requester_only requests' do
        titles = instance.data.map { |d| d[:info_request] }
        expect(titles).not_to include(requester_only_request)
        expect(titles).to include(normal_request)
      end
    end

    context 'when user is a pro admin' do
      let(:user) { FactoryBot.create(:pro_admin_user) }

      it 'includes requester_only requests' do
        titles = instance.data.map { |d| d[:info_request] }
        expect(titles).to include(requester_only_request)
      end
    end

    context 'when user is nil (public export)' do
      let(:user) { nil }

      it 'excludes requester_only requests' do
        titles = instance.data.map { |d| d[:info_request] }
        expect(titles).not_to include(requester_only_request)
        expect(titles).to include(normal_request)
      end
    end

    context 'when user is a non-owner' do
      let(:user) { FactoryBot.create(:user) }

      it 'excludes requester_only requests' do
        titles = instance.data.map { |d| d[:info_request] }
        expect(titles).not_to include(requester_only_request)
        expect(titles).to include(normal_request)
      end
    end
  end

  describe '#data_for_web' do
    subject { instance.data_for_web }

    before do
      allow(instance).to receive(:data).and_return(
        [{ request: 'Foo', request_url: 'http://example.com' }]
      )
    end

    it 'combine keys into anchor links' do
      is_expected.to match_array [
        { request: '<a href="http://example.com">Foo</a>' }
      ]
    end
  end

  describe '#name' do
    let(:project) { instance_double('Project', id: 1, title: 'Test Project') }
    subject { instance.name }

    it 'returns a useful filename' do
      travel_to Time.utc(2019, 11, 18, 10, 30)
      is_expected.to(
        eq 'project-1-test_project-2019-11-18-103000.csv'
      )
      travel_back
    end
  end

  describe '#to_csv' do
    subject { instance.to_csv }

    it 'returns CSV string from metrics' do
      allow(instance).to receive(:data).and_return(
        [{ foo: 'Foo', bar: 'Bar' }]
      )

      is_expected.to eq <<~CSV
        foo,bar
        Foo,Bar
      CSV
    end
  end
end
