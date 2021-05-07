require 'spec_helper'

RSpec.describe Survey do
  describe '.enabled?' do
    subject { described_class.enabled? }

    context 'when SURVEY_URL is configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:survey_url).
          and_return('https://example.com')
      end

      it { is_expected.to eq true }
    end

    context 'when SURVEY_URL is not configured' do
      it { is_expected.to eq false }
    end
  end
end
