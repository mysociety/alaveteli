require 'spec_helper'

require_dependency 'project/queue'

RSpec.describe Project::Queue::SessionBackend do
  let(:primed_session) do
    {
      'projects' => {
        '1' => {
          'foo' => {
            'current' => nil,
            'skipped' => []
          }
        }
      }
    }
  end

  let(:backend) do
    described_class.new(primed_session, project_id: '1', queue_name: 'foo')
  end

  describe '.primed' do
    subject { described_class.primed({}, project, queue_name) }
    let(:project) { double(to_param: '1') }
    let(:queue_name) { :foo }

    it do
      is_expected.to eq(
        described_class.new(primed_session, project_id: '1', queue_name: 'foo')
      )
    end
  end

  describe '#current' do
    subject { backend.current }

    context 'when not set' do
      before { backend.clear_current }
      it { is_expected.to be_nil }
    end

    context 'when set' do
      before { backend.current = 1 }
      it { is_expected.to eq('1') }
    end

    context 'when set with an object' do
      before { backend.current = double(to_param: '1') }
      it { is_expected.to eq('1') }
    end
  end

  describe '#current=' do
    subject { backend.current = 1 }
    it { is_expected.to eq(1) }
  end

  describe '#clear_current' do
    subject { backend.clear_current }

    it { is_expected.to be_nil }

    it 'clears current' do
      expect(backend.current).to be_nil
    end
  end

  describe '#skip' do
    subject { backend.skip(1) }

    context 'when skipped was empty' do
      it { is_expected.to eq(%w(1)) }
    end

    context 'when skipped had items' do
      before { backend.skip(2) }
      it { is_expected.to eq(%w(2 1)) }
    end
  end

  describe '#skipped' do
    subject { backend.skipped }

    context 'when not set' do
      before { backend.clear_skipped }
      it { is_expected.to be_empty }
    end

    context 'when set' do
      before { backend.skip(1) }
      it { is_expected.to eq(%w(1)) }
    end
  end

  describe '#clear_skipped' do
    subject { backend.clear_skipped }

    it { is_expected.to be_empty }

    it 'clears skipped' do
      expect(backend.skipped).to be_empty
    end
  end

  describe '#==' do
    subject { backend == other }

    context 'when they are the same' do
      let(:other) { backend.dup }
      it { is_expected.to eq(true) }
    end

    context 'when the session differs' do
      let(:other) do
        described_class.new({}, project_id: '1', queue_name: 'foo')
      end

      it { is_expected.to eq(false) }
    end

    context 'when the project_id differs' do
      let(:other) do
        described_class.new(primed_session, project_id: '2', queue_name: 'foo')
      end

      it { is_expected.to eq(false) }
    end

    context 'when the queue_name differs' do
      let(:other) do
        described_class.new(primed_session, project_id: '1', queue_name: 'bar')
      end

      it { is_expected.to eq(false) }
    end
  end
end
