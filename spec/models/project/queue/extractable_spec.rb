require 'spec_helper'
require_dependency 'project/queue/extractable'

RSpec.describe Project::Queue::Extractable do
  include_context 'Project::Queue context'

  it_behaves_like 'Project::Queue'

  shared_context 'with a current request' do
    let(:backend) do
      backend = Project::Queue::SessionBackend.primed({}, project, :extractable)
      backend.current = current_request.to_param
      backend
    end
  end

  describe '#next' do
    subject { queue.next }

    context 'without a current request' do
      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.to eq(queue.next) }
    end

    context 'with a current request that can be extracted' do
      include_context 'with a current request'
      let(:current_request) { project.info_requests.extractable.last }
      it { is_expected.to eq(current_request) }
    end

    context 'with a current request that gets extracted elsewhere' do
      include_context 'with a current request'
      let(:current_request) { project.info_requests.extractable.last }

      before do
        FactoryBot.create(:project_submission,
                          :for_extraction,
                          info_request: current_request)
      end

      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(current_request) }
    end

    context 'when the request gets skipped' do
      let(:skipped_request) { queue.next }
      before { queue.skip(skipped_request) }
      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(skipped_request) }
    end

    context 'when the remembered request gets skipped' do
      include_context 'with a current request'
      let(:current_request) { project.info_requests.extractable.last }
      before { queue.skip(current_request) }
      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(current_request) }
    end

    context 'when all requests get skipped' do
      before do
        project.info_requests.extractable.each do |info_request|
          queue.skip(info_request)
        end
      end

      it { is_expected.to be_nil }
    end

    context 'after clearing skipped requests' do
      before do
        project.info_requests.extractable.each do |info_request|
          queue.skip(info_request)
        end

        queue.clear_skipped
      end

      it { is_expected.to be_a(InfoRequest) }
    end

    context 'when there are no requests left in the queue' do
      before do
        2.times do
          FactoryBot.create(:project_submission,
                            :for_extraction,
                            info_request: queue.next)
        end
      end

      it { is_expected.to be_nil }
    end

    it 'only includes extractable requests' do
      extractable = project.info_requests.extractable.to_a

      requests = extractable.size.times.map do
        request = queue.next
        FactoryBot.create(:project_submission,
                          :for_extraction,
                          info_request: queue.next)
        request
      end

      expect(queue.next).to be_nil
      expect(requests).to match_array(extractable)
    end
  end

  describe '#include?' do
    subject { queue.include?(info_request) }

    context 'when the request is in the queue' do
      let(:info_request) { project.info_requests.extractable.first }
      it { is_expected.to eq(true) }
    end

    context 'when the request is not in the queue' do
      let(:info_request) { FactoryBot.create(:info_request) }
      it { is_expected.to eq(false) }
    end
  end
end
