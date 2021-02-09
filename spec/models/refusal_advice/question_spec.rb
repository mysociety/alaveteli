require 'spec_helper'

RSpec.describe RefusalAdvice::Question do
  let(:data) do
    {
      label: {
        plain: 'Refusing a request on cost grounds...'
      },
      hint: {
        plain: 'Note that...'
      },
      options: [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
      ]
    }
  end

  let(:question) { described_class.new(data) }

  describe '#label' do
    subject { question.label }

    it 'returns hash with valid render options' do
      is_expected.
        to eq('plain' => 'Refusing a request on cost grounds...')
    end

    context 'with HTML render option' do
      let(:data) { { label: { html: '<h1>Hello World</h1>' } } }

      it 'marks HTML as being safe' do
        is_expected.to eq('html' => '<h1>Hello World</h1>')
        expect(question.label['html']).to be_html_safe
      end
    end

    context 'with invalid render option' do
      let(:data) { { label: { invalid: 'Boom' } } }

      it 'raises unpermitted parameter error' do
        expect { question.label }.to raise_error(
          ActionController::UnpermittedParameters,
          'found unpermitted parameter: :invalid'
        )
      end
    end

    context 'without render options' do
      before { data.delete(:label) }

      it 'renders an empty string' do
        is_expected.to eq(plain: '')
      end
    end
  end

  describe '#hint' do
    subject { question.hint }

    it 'returns hash with valid render options' do
      is_expected.to eq('plain' => 'Note that...')
    end

    context 'with HTML render option' do
      let(:data) { { hint: { html: '<h1>Hello World</h1>' } } }

      it 'marks HTML as being safe' do
        is_expected.to eq('html' => '<h1>Hello World</h1>')
        expect(question.hint['html']).to be_html_safe
      end
    end

    context 'with invalid render option' do
      let(:data) { { hint: { invalid: 'Boom' } } }

      it 'raises unpermitted parameter error' do
        expect { question.hint }.to raise_error(
          ActionController::UnpermittedParameters,
          'found unpermitted parameter: :invalid'
        )
      end
    end

    context 'without render options' do
      before { data.delete(:hint) }

      it 'renders an empty string' do
        is_expected.to eq(plain: '')
      end
    end
  end

  describe '#options' do
    subject { question.options }

    it 'maps options into struct objects' do
      is_expected.to match_array(
        [OpenStruct.new(label: 'Yes', value: 'yes'),
         OpenStruct.new(label: 'No', value: 'no')]
      )
    end
  end

  describe '#to_partial_path' do
    subject { question.to_partial_path }
    it { is_expected.to eq 'help/refusal_advice/question' }
  end
end
