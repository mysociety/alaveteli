require 'spec_helper'

RSpec.describe RefusalAdvice::Suggestion do
  let(:data) do
    {
      action: 'reply',
      response_template: 'i-only-need-some-of-the-information'
    }
  end

  let(:suggestion) { described_class.new(data) }

  describe '#action' do
    subject { suggestion.action }
    it { is_expected.to eq('reply') }
  end

  describe '#response_template' do
    subject { suggestion.response_template }
    it { is_expected.to eq('i-only-need-some-of-the-information') }
  end
end
