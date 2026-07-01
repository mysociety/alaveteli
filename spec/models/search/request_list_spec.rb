require 'spec_helper'

RSpec.describe Search::RequestList do
  describe '#call' do
    it 'filters searchable requests by their status' do
      successful = FactoryBot.create(:info_request)
      successful.set_described_state('successful')
      waiting = FactoryBot.create(:info_request)

      result = described_class.
               new({ latest_status: 'successful' }, 1, 25, 100).call

      expect(result[:results]).to include(successful)
      expect(result[:results]).not_to include(waiting)
    end

    it 'restricts by a free-text query through the search backend' do
      match = FactoryBot.create(:info_request)
      stub_request_search_results(items: [match])

      result = described_class.
               new({ query: 'badger', latest_status: 'all' }, 1, 25, 100).call

      expect(result[:results]).to eq([match])
    end

    it 'caps show_no_more_than at max_results' do
      3.times { FactoryBot.create(:info_request) }

      result = described_class.new({ latest_status: 'all' }, 1, 25, 2).call

      expect(result[:matches_estimated]).to be >= 3
      expect(result[:show_no_more_than]).to eq(2)
    end
  end
end
