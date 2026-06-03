require 'spec_helper'

RSpec.describe Search::Context::InfoRequest do
  let(:request) { double }

  describe '#info_request' do
    it 'returns the wrapped info request' do
      context = described_class.new(request)
      expect(context.info_request).to eq(request)
    end
  end

  describe '#similar_requests' do
    it 'delegates to Search.similar' do
      searcher = double
      expect(Search).to receive(:similar).with(request).and_return(searcher)
      expect(described_class.new(request).similar_requests).to eq(searcher)
    end
  end
end
