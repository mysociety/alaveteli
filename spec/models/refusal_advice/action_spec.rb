require 'spec_helper'

RSpec.describe RefusalAdvice::Action do
  let(:data) do
    {
      title: 'It looks like you have grounds for a review:',
      suggestions: [
        { id: 'confirmation-not-too-costly' }
      ]
    }
  end

  let(:action) { described_class.new(data) }

  describe '#title' do
    subject { action.title }
    it { is_expected.to eq('It looks like you have grounds for a review:') }
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
end
