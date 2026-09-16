require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::RequestSearch, :xapian do
  describe '#results' do
    subject(:results) do
      described_class.new('daftest comment').results(page: 1, per_page: 25)
    end

    it 'returns the request behind the matching event' do
      expect(results.items.map { |r| r[:model] }).
        to eq([info_requests(:fancy_dog_request)])
    end
  end
end
