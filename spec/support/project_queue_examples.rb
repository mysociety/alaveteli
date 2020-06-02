RSpec.shared_examples 'Project::Queue' do
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
