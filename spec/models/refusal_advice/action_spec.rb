require 'spec_helper'

RSpec.describe RefusalAdvice::Action do
  let(:data) do
    {
      title: 'Ask for an internal review',
      header: 'It looks like you have grounds for a review!',
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
