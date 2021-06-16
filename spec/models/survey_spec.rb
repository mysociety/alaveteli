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

  describe '.url' do
    subject { described_class.url }

    context 'when SURVEY_URL is configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:survey_url).
          and_return('https://example.com')
      end

      it { is_expected.to eq 'https://example.com' }
    end

    context 'when SURVEY_URL is not configured' do
      it { is_expected.to eq '' }
    end
  end

  describe '.date_range' do
    subject { described_class.date_range }

    it { is_expected.to_not cover(2.weeks.ago - 1.day) }
    it { is_expected.to cover(2.weeks.ago) }
    it { is_expected.to_not cover(2.weeks.ago + 1.day) }
  end

  describe '#url' do
    subject { described_class.new(public_body).url }

    let(:public_body) { FactoryBot.build(:public_body) }

    before do
      allow(AlaveteliConfiguration).to receive(:survey_url).
        and_return('https://example.com')
    end

    context 'when public body has 10 different requesters' do
      before do
        10.times { FactoryBot.create(:info_request, public_body: public_body) }
      end

      it 'adds authority_id GET param to base survey url' do
        is_expected.to eq(
          "https://example.com?authority_id=#{public_body.to_param}"
        )
      end
    end

    context 'when public body has less than 10 different requesters' do
      it 'returns base survey url' do
        is_expected.to eq 'https://example.com'
      end
    end
  end
end
