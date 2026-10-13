require 'spec_helper'

RSpec.describe Search::Adapter do
  subject(:adapter) { described_class.new('test query', sort_order: :date) }

  describe '#initialize' do
    it 'stores the query' do
      expect(adapter.query).to eq('test query')
    end

    it 'merges options with defaults' do
      expect(adapter.options).to eq(
        include_hidden: false,
        sort_order: :date
      )
    end

    it 'uses defaults when no options given' do
      default_adapter = described_class.new
      expect(default_adapter.options).to eq(
        include_hidden: false,
        sort_order: :relevance
      )
    end
  end

  describe '#results' do
    it 'raises NotImplementedError' do
      expect { adapter.results }.to raise_error(
        NotImplementedError, 'Subclasses must implement the results method'
      )
    end
  end

  describe '#first' do
    it 'returns items and has_more flag from a single page search' do
      results = Search::Results.new(
        items: %w[a b], total_estimate: 5, per_page: 2
      )
      allow(adapter).to receive(:results).with(
        page: 1, per_page: 3
      ).and_return(results)

      items, has_more = adapter.first(3)
      expect(items).to eq(%w[a b])
      expect(has_more).to eq(true)
    end
  end

  describe '#create_search_results' do
    it 'returns a Results instance' do
      results = adapter.send(
        :create_search_results,
        items: %w[a], total_estimate: 1
      )
      expect(results).to be_a(Search::Results)
      expect(results.items).to eq(%w[a])
    end
  end

  describe '#calculate_offset' do
    it 'calculates zero-based offset from page and per_page' do
      expect(adapter.send(:calculate_offset, 1, 10)).to eq(0)
      expect(adapter.send(:calculate_offset, 3, 10)).to eq(20)
    end
  end
end
