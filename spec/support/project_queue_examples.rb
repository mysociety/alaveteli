RSpec.shared_examples 'Project::Queue' do
  describe '#==' do
    subject { queue == other_queue }

    context 'when the queue is the same' do
      let(:other_queue) { described_class.new(project, session) }
      it { is_expected.to eq(true) }
    end

    context 'with a different project' do
      let(:other_queue) { described_class.new(double, session) }
      it { is_expected.to eq(false) }
    end

    context 'with a different session' do
      let(:other_queue) { described_class.new(project, double) }
      it { is_expected.to eq(false) }
    end
  end
end
