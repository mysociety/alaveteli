require 'spec_helper'

RSpec.describe Search::RequestList do
  describe '#call' do
    it 'caps show_no_more_than at max_results' do
      requests = Array.new(2) { FactoryBot.build(:info_request) }

      searcher = double('FullTextSearch')
      allow(searcher).to receive(:results).
        and_return(build_search_results(items: requests, total: 200))
      allow(Search).to receive(:request_search).and_return(searcher)

      results = described_class.new({ latest_status: 'all' }, 1, 25, 50).call

      expect(results[:show_no_more_than]).to eq(50)
      expect(results[:matches_estimated]).to eq(200)
      expect(results[:results].size).to eq(2)
    end

    it 'uses matches_estimated if less than max_results' do
      requests = Array.new(2) { FactoryBot.build(:info_request) }

      searcher = double('FullTextSearch')
      allow(searcher).to receive(:results).
        and_return(build_search_results(items: requests, total: 10))
      allow(Search).to receive(:request_search).and_return(searcher)

      results = described_class.new({ latest_status: 'all' }, 1, 25, 50).call

      expect(results[:show_no_more_than]).to eq(10)
      expect(results[:matches_estimated]).to eq(10)
      expect(results[:results].size).to eq(2)
    end
  end
end
