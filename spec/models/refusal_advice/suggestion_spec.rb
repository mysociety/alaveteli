require 'spec_helper'

RSpec.describe RefusalAdvice::Suggestion do
  let(:data) do
    {
      action: 'reply',
      advice: { plain: 'Refusing a request on cost grounds...' },
      response_template: 'i-only-need-some-of-the-information'
    }
  end

  let(:suggestion) { described_class.new(data) }

  describe '#action' do
    subject { suggestion.action }
    it { is_expected.to eq('reply') }
  end

  describe '#advice' do
    subject { suggestion.advice }

    it 'returns hash with valid render options' do
      is_expected.
        to eq('plain' => 'Refusing a request on cost grounds...')
    end

    context 'with HTML render option' do
      let(:data) { { advice: { html: '<h1>Hello World</h1>' } } }

      it 'marks HTML as being safe' do
        is_expected.to eq('html' => '<h1>Hello World</h1>')
        expect(suggestion.advice['html']).to be_html_safe
      end
    end

    context 'with invalid render option' do
      let(:data) { { advice: { invalid: 'Boom' } } }

      it 'raises unpermitted parameter error' do
        expect { suggestion.advice }.to raise_error(
          ActionController::UnpermittedParameters,
          'found unpermitted parameter: :invalid'
        )
      end
    end
  end

  describe '#response_template' do
    subject { suggestion.response_template }
    it { is_expected.to eq('i-only-need-some-of-the-information') }
  end

  describe '#to_partial_path' do
    subject { suggestion.to_partial_path }
    it { is_expected.to eq 'help/refusal_advice/suggestion' }
  end
end
