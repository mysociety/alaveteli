require 'spec_helper'

RSpec.describe RefusalAdvice::Suggestion do
  let(:data) do
    {
    }
  end

  let(:suggestion) { described_class.new(data) }

  describe '#to_partial_path' do
    subject { suggestion.to_partial_path }
    it { is_expected.to eq 'help/refusal_advice/suggestion' }
  end
end
