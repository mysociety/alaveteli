require 'spec_helper'

RSpec.describe Search::Results do
  def build_results(overrides = {})
    defaults = {
      items: [{ model: 'a' }, { model: 'b' }, { model: 'c' }],
      total_estimate: 10,
      current_page: 1,
      per_page: 3,
      offset: 0
    }
    described_class.new(**defaults.merge(overrides))
  end

  describe '#initialize' do
    it 'coerces items to an array' do
      results = described_class.new(items: nil, total_estimate: 0)
      expect(results.items).to eq([])
    end

    it 'coerces total_estimate to an integer' do
      results = described_class.new(items: [], total_estimate: '5')
      expect(results.total_estimate).to eq(5)
    end
  end

  describe '#matches_estimated' do
    it 'is an alias for total_estimate' do
      results = build_results(total_estimate: 42)
      expect(results.matches_estimated).to eq(42)
    end
  end

  describe '#results' do
    it 'is an alias for items' do
      items = [1, 2, 3]
      results = build_results(items: items)
      expect(results.results).to eq(items)
    end
  end

  describe '#each' do
    it 'yields each item' do
      items = %w[a b c]
      results = build_results(items: items)
      expect(results.map(&:itself)).to eq(items)
    end
  end

  describe 'collection methods' do
    it 'reports any?' do
      expect(build_results).to be_any
      expect(build_results(items: [])).not_to be_any
    end

    it 'reports empty?' do
      expect(build_results).not_to be_empty
      expect(build_results(items: [])).to be_empty
    end

    it 'is always present even when empty' do
      expect(build_results(items: [])).to be_present
    end

    it 'returns count, size, and length' do
      results = build_results
      expect(results.count).to eq(3)
      expect(results.size).to eq(3)
      expect(results.length).to eq(3)
    end

    it 'returns first and last' do
      results = build_results(items: %w[x y z])
      expect(results.first).to eq('x')
      expect(results.last).to eq('z')
    end
  end

  describe '#has_normal_search_terms?' do
    it 'returns false by default' do
      expect(build_results).not_to have_normal_search_terms
    end

    it 'returns true when set' do
      results = build_results(has_normal_search_terms: true)
      expect(results).to have_normal_search_terms
    end
  end

  describe '#words_to_highlight' do
    it 'returns empty array by default' do
      expect(build_results.words_to_highlight).to eq([])
    end

    it 'returns the configured words' do
      results = build_results(words_to_highlight: %w[foo bar])
      expect(results.words_to_highlight).to eq(%w[foo bar])
    end

    it 'accepts options for compatibility' do
      results = build_results(words_to_highlight: %w[foo])
      expect(results.words_to_highlight(regex: true)).to eq(%w[foo])
    end
  end

  describe '#spelling_correction' do
    it 'returns nil by default' do
      expect(build_results.spelling_correction).to be_nil
    end

    it 'returns the configured correction' do
      results = build_results(spelling_correction: 'test')
      expect(results.spelling_correction).to eq('test')
    end
  end

  describe 'pagination' do
    it 'detects more results available' do
      results = build_results(total_estimate: 10, offset: 0)
      expect(results).to have_more
    end

    it 'detects no more results' do
      results = build_results(
        items: %w[a b c], total_estimate: 3, offset: 0
      )
      expect(results).not_to have_more
    end

    it 'detects previous page available' do
      results = build_results(current_page: 2)
      expect(results).to have_previous
    end

    it 'detects no previous page on first page' do
      results = build_results(current_page: 1)
      expect(results).not_to have_previous
    end

    it 'returns next_page number' do
      results = build_results(current_page: 1, total_estimate: 10)
      expect(results.next_page).to eq(2)
    end

    it 'returns nil for next_page on last page' do
      results = build_results(
        items: %w[a b c], total_estimate: 3, current_page: 1, offset: 0
      )
      expect(results.next_page).to be_nil
    end

    it 'returns previous_page number' do
      results = build_results(current_page: 3)
      expect(results.previous_page).to eq(2)
    end

    it 'returns nil for previous_page on first page' do
      results = build_results(current_page: 1)
      expect(results.previous_page).to be_nil
    end

    it 'calculates total_pages' do
      results = build_results(total_estimate: 10, per_page: 3)
      expect(results.total_pages).to eq(4)
    end

    it 'returns 1 for total_pages when per_page is 0' do
      results = build_results(per_page: 0)
      expect(results.total_pages).to eq(1)
    end

    it 'calculates first_item_number' do
      results = build_results(offset: 6)
      expect(results.first_item_number).to eq(7)
    end

    it 'returns 0 for first_item_number when empty' do
      results = build_results(items: [])
      expect(results.first_item_number).to eq(0)
    end

    it 'calculates last_item_number' do
      results = build_results(offset: 6)
      expect(results.last_item_number).to eq(9)
    end

    it 'returns 0 for last_item_number when empty' do
      results = build_results(items: [])
      expect(results.last_item_number).to eq(0)
    end
  end

  describe '#to_a' do
    it 'returns items as an array' do
      results = build_results(items: %w[a b])
      expect(results.to_a).to eq(%w[a b])
    end
  end

  describe '#to_s' do
    it 'returns a readable summary' do
      results = build_results(total_estimate: 10, current_page: 2)
      expect(results.to_s).to eq('SearchResults(3/10 items, page 2)')
    end
  end

  describe '#inspect' do
    it 'returns a debug-friendly string' do
      results = build_results
      expect(results.inspect).to include('Search::Results')
      expect(results.inspect).to include('items=3')
      expect(results.inspect).to include('total_estimate=10')
    end
  end
end
