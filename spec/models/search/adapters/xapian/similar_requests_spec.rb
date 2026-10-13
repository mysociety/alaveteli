require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::SimilarRequests, :xapian do
  let(:info_request) { info_requests(:fancy_dog_request) }

  describe '#initialize' do
    it 'stores the info request' do
      sr = described_class.new(info_request)
      expect(sr.info_request).to eq(info_request)
    end
  end

  describe '#results' do
    it 'returns a Search::Results object' do
      sr = described_class.new(info_request)
      results = sr.results(page: 1, per_page: 10)
      expect(results).to be_a(Search::Results)
    end

    it 'returns InfoRequest objects' do
      sr = described_class.new(info_request)
      results = sr.results(page: 1, per_page: 10)
      results.items.each do |item|
        expect(item).to be_a(InfoRequest)
      end
    end

    it 'does not include the original request' do
      sr = described_class.new(info_request)
      results = sr.results(page: 1, per_page: 10)
      expect(results.items).not_to include(info_request)
    end

    it 'sets current_page and per_page' do
      sr = described_class.new(info_request)
      results = sr.results(page: 1, per_page: 5)
      expect(results.current_page).to eq(1)
      expect(results.per_page).to eq(5)
    end
  end

  describe '#first' do
    it 'returns an array of requests and a has_more flag' do
      sr = described_class.new(info_request)
      requests, has_more = sr.first(5)
      expect(requests).to be_an(Array)
      expect([true, false]).to include(has_more)
    end

    it 'returns InfoRequest objects' do
      sr = described_class.new(info_request)
      requests, _has_more = sr.first(5)
      requests.each do |item|
        expect(item).to be_a(InfoRequest)
      end
    end
  end
end
