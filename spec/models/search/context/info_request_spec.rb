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

  describe '#request_list' do
    it 'delegates to Search::RequestList' do
      filters = { latest_status: 'all' }
      list = instance_double(Search::RequestList, call: :list_result)
      expect(Search::RequestList).to receive(:new).
        with(filters, 1, 25, 50).and_return(list)

      result = described_class.new(request).request_list(filters, 1, 25, 50)
      expect(result).to eq(:list_result)
    end
  end

  describe '#recent_requests' do
    it 'delegates to Search::RecentRequests' do
      recent = instance_double(Search::RecentRequests, call: :recent_result)
      expect(Search::RecentRequests).to receive(:new).and_return(recent)

      expect(described_class.new(request).recent_requests).to eq(:recent_result)
    end
  end
end
