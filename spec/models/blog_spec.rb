require 'spec_helper'

RSpec.describe Blog do
  describe '.enabled?' do
    subject { described_class.enabled? }

    context 'when feed is configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com')
      end

      it { is_expected.to eq(true) }
    end

    context 'when feed is not configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).and_return('')
      end

      it { is_expected.to eq(false) }
    end
  end
end
