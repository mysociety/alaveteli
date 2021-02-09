require 'spec_helper'

RSpec.describe RefusalAdvice::Block do
  let(:data) do
    {
      id: 'yes-they-have-provided-information',
      show_if: [
        { id: 'have-they-already-provided-information',
          operator: 'is',
          value: 'yes' },
        { id: 'section_12',
          operator: 'include',
          value: 'no' }
      ]
    }
  end

  let(:block) { described_class.new(data) }

  describe '#id' do
    subject { block.id }
    it { is_expected.to eq('yes-they-have-provided-information') }
  end

  describe '#show_if' do
    subject { block.show_if }

    it 'returns show if data as given' do
      is_expected.to match_array(data[:show_if])
    end
  end

  describe '#==' do
    subject { a == b }

    context 'with the same data' do
      let(:a) { described_class.new(id: 'bar') }
      let(:b) { described_class.new(id: 'bar') }
      it { is_expected.to eq(true) }
    end

    context 'with different data' do
      let(:a) { described_class.new(id: 'bar') }
      let(:b) { described_class.new(id: 'foo') }
      it { is_expected.to eq(false) }
    end
  end
end
