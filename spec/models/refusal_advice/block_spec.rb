require 'spec_helper'

RSpec.describe RefusalAdvice::Block do
  let(:data) do
    {
      id: 'yes-they-have-provided-information',
      label: {
        plain: 'Refusing a request on cost grounds...'
      },
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

  describe '#label' do
    subject { block.label }

    it 'returns hash with valid render options' do
      is_expected.
        to eq('plain' => 'Refusing a request on cost grounds...')
    end

    context 'with HTML render option' do
      let(:data) { { label: { html: '<h1>Hello World</h1>' } } }

      it 'marks HTML as being safe' do
        is_expected.to eq('html' => '<h1>Hello World</h1>')
        expect(block.label['html']).to be_html_safe
      end
    end

    context 'with invalid render option' do
      let(:data) { { label: { invalid: 'Boom' } } }

      it 'raises unpermitted parameter error' do
        expect { block.label }.to raise_error(
          ActionController::UnpermittedParameters,
          'found unpermitted parameter: :invalid'
        )
      end
    end
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
