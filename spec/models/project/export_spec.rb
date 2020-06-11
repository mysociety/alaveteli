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
end
