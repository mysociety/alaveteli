require 'spec_helper'
require 'models/project/queue_spec'

RSpec.describe Project::Queue::Classifiable do
  include_context 'Project::Queue context'

  it_behaves_like 'Project::Queue'

  describe '#next' do
    subject { queue.next }

    context 'with a current request' do
      let(:current_request) { project.info_requests.classifiable.last }
      before { queue.current(current_request.id) }
      it { is_expected.to eq(current_request) }
    end

    context 'with a current request that gets classified elsewhere' do
      let(:info_request) { project.info_requests.classifiable.last }

      before do
        queue.current(info_request.id)
        info_request.update(awaiting_description: false)
      end

      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(info_request) }
    end

    context 'without a current request' do
      before { queue.clear_current }
      it { is_expected.to be_a(InfoRequest) }
    end

    context 'when there are no requests left in the queue' do
      before do
        2.times do
          queue.next.update(awaiting_description: false)
        end
      end

      it { is_expected.to be_nil }
    end

    it 'only includes classifiable requests' do
      queued_requests = project.info_requests.map do |info_request|
        queue.current(info_request.id)
        queue.next
      end

      expect(queued_requests.compact.uniq).
        to match_array(project.info_requests.classifiable)
    end
  end

  describe '#include?' do
    subject { queue.include?(info_request) }

    context 'when the request is in the queue' do
      let(:info_request) { project.info_requests.classifiable.first }
      it { is_expected.to eq(true) }
    end

    context 'when the request is not in the queue' do
      let(:info_request) { FactoryBot.create(:info_request) }
      it { is_expected.to eq(false) }
    end
  end
end
