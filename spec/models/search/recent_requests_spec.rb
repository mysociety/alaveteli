require 'spec_helper'

RSpec.describe Search::RecentRequests do
  describe '#call' do
    it 'returns recent successful requests and flags them all successful' do
      5.times do
        FactoryBot.create(:info_request).set_described_state('successful')
      end

      requests, all_successful = described_class.new.call

      expect(requests.size).to eq(5)
      expect(requests).to all(be_a(InfoRequest))
      expect(all_successful).to be true
    end

    it 'backfills with other recent requests when fewer than five succeed' do
      # ensure fewer than five successful requests exist
      InfoRequest.update_all(described_state: 'waiting_response')
      successful = FactoryBot.create(:info_request)
      successful.set_described_state('successful')
      other = FactoryBot.create(:info_request)

      requests, all_successful = described_class.new.call

      expect(requests).to include(successful, other)
      expect(all_successful).to be false
    end
  end
end
