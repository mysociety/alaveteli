require 'spec_helper'

require_dependency 'project/queue/session_backend'

RSpec.describe Project::Queue do
  let(:project) do
    project = FactoryBot.create(:project,
                                contributors_count: 2,
                                classifiable_requests_count: 2,
                                extractable_requests_count: 2)

    # HACK: extractable_requests_count uses attributes_for. The factory it
    # relies on uses an after_create callback to call set_described_state to
    # create an event and update the state, meaning our
    # extractable_requests_count doesn't actually work.
    project.info_requests.last(2).each do |info_request|
      info_request.update(described_state: 'successful')
    end

    project
  end

  let(:current_user) { project.contributors.last }

  let(:info_requests) { project.info_requests }

  let(:backend) { Project::Queue::SessionBackend.primed({}, project, :test) }

  let(:queue) { Project::Queue.new(info_requests, backend) }

  shared_context 'with a current request' do
    before { backend.current = current_request.to_param }
  end

  describe '.classifiable' do
    subject { described_class.classifiable(project, {}) }

    it 'sets up a classifiable queue for a project' do
      backend =
        Project::Queue::SessionBackend.primed({}, project, :classifiable)
      queue = described_class.new(project.info_requests.classifiable, backend)

      expect(subject).to eq(queue)
    end
  end

  describe '.extractable' do
    subject { described_class.extractable(project, {}) }

    it 'sets up a extractable queue for a project' do
      backend =
        Project::Queue::SessionBackend.primed({}, project, :extractable)
      queue = described_class.new(project.info_requests.extractable, backend)

      expect(subject).to eq(queue)
    end
  end

  describe '#next' do
    subject { queue.next }

    context 'without a current request' do
      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.to eq(queue.next) }
    end

    context 'with a current request' do
      include_context 'with a current request'
      let(:current_request) { info_requests.last }
      it { is_expected.to eq(current_request) }
    end

    context 'with a current request that is no longer in the queue' do
      include_context 'with a current request'
      let(:current_request) { info_requests.last }
      before { current_request.destroy }

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
      let(:current_request) { info_requests.last }
      before { queue.skip(current_request) }
      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(current_request) }
    end

    context 'when all requests get skipped' do
      before { info_requests.each { |info_request| queue.skip(info_request) } }
      it { is_expected.to be_nil }
    end

    context 'after clearing skipped requests' do
      before do
        info_requests.each { |info_request| queue.skip(info_request) }
        queue.clear_skipped
      end

      it { is_expected.to be_a(InfoRequest) }
    end

    context 'when there are no requests left in the queue' do
      before { info_requests.destroy_all }
      it { is_expected.to be_nil }
    end
  end

  describe '#skip' do
    subject { queue.skip(info_request) }

    context 'when the skipped list is empty' do
      let(:info_request) { double(to_param: '1') }
      it { is_expected.to match_array(%w(1)) }
    end

    context 'when adding to the skipped list' do
      let(:info_request) { double(to_param: '1') }
      before { queue.skip(double(to_param: '2')) }
      it { is_expected.to match_array(%w(2 1)) }
    end
  end

  describe '#clear_skipped' do
    subject { queue.clear_skipped }
    it { is_expected.to be_empty }
  end

  describe '#include?' do
    subject { queue.include?(info_request) }

    context 'when the request is in the queue' do
      let(:info_request) { info_requests.first }
      it { is_expected.to eq(true) }
    end

    context 'when the request is not in the queue' do
      let(:info_request) { FactoryBot.create(:info_request) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#==' do
    subject { queue == other_queue }

    context 'when the queue is the same' do
      let(:other_queue) { described_class.new(info_requests, backend) }
      it { is_expected.to eq(true) }
    end

    context 'with different info_requests' do
      let(:other_queue) { described_class.new(double.as_null_object, backend) }
      it { is_expected.to eq(false) }
    end

    context 'with a different backend' do
      let(:other_queue) do
        described_class.new(info_requests, double.as_null_object)
      end

      it { is_expected.to eq(false) }
    end
  end
end
