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
    it { is_expected.to eq('It looks like you have grounds for a review!') }
  end

  describe '#suggestions' do
    subject { action.suggestions }
    it { is_expected.to all(be_a(RefusalAdvice::Suggestion)) }
    it do
      is_expected.to match_array(
        RefusalAdvice::Suggestion.new(id: 'confirmation-not-too-costly')
      )
    end
  end

  describe '#to_partial_path' do
    subject { action.to_partial_path }
    it { is_expected.to eq 'help/refusal_advice/action' }
  end
end
