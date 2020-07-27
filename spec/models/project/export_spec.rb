require 'spec_helper'

RSpec.describe Project::Export do
  let(:project) { instance_double('Project') }
  let(:instance) { described_class.new(project) }

  describe '#data' do
    subject { instance.data }

    let(:info_request_a) { instance_double('InfoRequest') }
    let(:info_request_b) { instance_double('InfoRequest') }

    before do
      allow(project).to receive_message_chain(:info_requests, :extracted).
        and_return([info_request_a, info_request_b])
    end

    it 'individualy exports info requests' do
      expect(Project::Export::InfoRequest).to receive(:new).
        with(project, info_request_a).
        and_return(double(data: { header: 'DATA A' }))
      expect(Project::Export::InfoRequest).to receive(:new).
        with(project, info_request_b).
        and_return(double(data: { header: 'DATA B' }))

      is_expected.to match_array [{ header: 'DATA A' }, { header: 'DATA B' }]
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
