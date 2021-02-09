require 'spec_helper'

RSpec.describe RefusalAdvice::Action do
  let(:data) do
    {
      title: 'Ask for an internal review',
      header: 'It looks like you have grounds for a review!',
      body: { plain: 'Refusing a request on cost grounds...' },
      button: 'Help me send an internal review',
      suggestions: [
        { id: 'confirmation-not-too-costly' }
      ]
    }
  end

  let(:action) { described_class.new(data) }

  describe '#title' do
    subject { action.title }
    it { is_expected.to eq('Ask for an internal review') }
  end

  describe '#header' do
    subject { action.header }

    context 'when set' do
      it { is_expected.to eq('It looks like you have grounds for a review!') }
    end

    context 'when not set' do
      before { data.delete(:header) }
      it { is_expected.to eq('Ask for an internal review') }
    end
  end

  describe '#body' do
    subject { action.body }

    it 'returns hash with valid render options' do
      is_expected.
        to eq('plain' => 'Refusing a request on cost grounds...')
    end

    context 'with HTML render option' do
      let(:data) { { body: { html: '<h1>Hello World</h1>' } } }

      it 'marks HTML as being safe' do
        is_expected.to eq('html' => '<h1>Hello World</h1>')
        expect(action.body['html']).to be_html_safe
      end
    end

    context 'with invalid render option' do
      let(:data) { { body: { invalid: 'Boom' } } }

      it 'raises unpermitted parameter error' do
        expect { action.body }.to raise_error(
          ActionController::UnpermittedParameters,
          'found unpermitted parameter: :invalid'
        )
      end
    end

    context 'without render options' do
      before { data.delete(:body) }

      it 'renders an empty string' do
        is_expected.to eq(plain: '')
      end
    end
  end

  describe '#button' do
    subject { action.button }

    context 'when set' do
      it { is_expected.to eq('Help me send an internal review') }
    end

    context 'when not set' do
      before { data.delete(:button) }
      it { is_expected.to eq('Ask for an internal review') }
    end
  end

  describe '#suggestions' do
    subject { action.suggestions }

    it { is_expected.to all(be_a(RefusalAdvice::Suggestion)) }

    it 'returns an array including expected suggestion' do
      is_expected.to match_array(
        RefusalAdvice::Suggestion.new(id: 'confirmation-not-too-costly')
      )
    end

    context 'when no suggestions are defined' do
      before { data.delete(:suggestions) }
      it { is_expected.to be_empty }
      it { is_expected.to be_an(Array) }
    end
  end

  describe '#to_partial_path' do
    subject { action.to_partial_path }
    it { is_expected.to eq 'help/refusal_advice/action' }
  end
end
