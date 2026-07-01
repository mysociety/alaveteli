##
# Helper methods for mocking the Search module in tests.
#
# Usage in specs:
#   include SearchHelpers
#
#   it 'searches for bodies' do
#     stub_search_results(items: [public_body], total: 1)
#     # or for typeahead:
#     stub_typeahead_results(items: [public_body], total: 1)
#   end
#
module SearchHelpers
  ##
  # Lightweight stand-in for a search backend searcher object.
  # Returns empty Search::Results from .results and [[], false] from .first.
  #
  class NullSearcher
    def results(page: 1, per_page: 25)
      Search::Results.new(
        items: [],
        total_estimate: 0,
        current_page: page,
        per_page: per_page,
        offset: (page - 1) * per_page
      )
    end

    def first(_limit = 10)
      [[], false]
    end
  end

  ##
  # Guard prepended onto the search backend adapter. When the global stub
  # flag is set it returns a null searcher, avoiding any Xapian database
  # access.
  #
  module Guard
    def search(query, models:, **options)
      SearchHelpers.stubbed? ? SearchHelpers::NullSearcher.new : super
    end

    def request_search(query, **options)
      SearchHelpers.stubbed? ? SearchHelpers::NullSearcher.new : super
    end

    def typeahead(query, model:, **options)
      SearchHelpers.stubbed? ? SearchHelpers::NullSearcher.new : super
    end

    def similar(record)
      SearchHelpers.stubbed? ? SearchHelpers::NullSearcher.new : super
    end
  end

  def self.stubbed?
    Thread.current[:search_helpers_stubbed]
  end

  def self.stubbed=(value)
    Thread.current[:search_helpers_stubbed] = value
  end

  # Stub Search.search to return a Results object with the given items
  def stub_search_results(items: [], total: nil, spelling_correction: nil,
                          words_to_highlight: [], has_normal_search_terms: true)
    total ||= items.size
    results = build_search_results(
      items: items,
      total: total,
      spelling_correction: spelling_correction,
      words_to_highlight: words_to_highlight,
      has_normal_search_terms: has_normal_search_terms
    )

    searcher = double('FullTextSearch', results: results)
    allow(Search).to receive(:search).and_return(searcher)
    allow(Search).to receive(:request_search).and_return(searcher)
    allow(Search.backend).to receive(:search).and_return(searcher)
    allow(Search.backend).to receive(:request_search).and_return(searcher)
    results
  end

  # Stub Search.typeahead to return a Results object with the given items
  def stub_typeahead_results(items: [], total: nil, spelling_correction: nil,
                             words_to_highlight: [])
    total ||= items.size
    results = build_search_results(
      items: items,
      total: total,
      spelling_correction: spelling_correction,
      words_to_highlight: words_to_highlight
    )

    searcher = double('Typeahead', results: results)
    allow(Search).to receive(:typeahead).and_return(searcher)
    allow(Search.backend).to receive(:typeahead).and_return(searcher)
    results
  end

  # Stub similar requests search
  def stub_similar_requests(items: [], total: nil)
    total ||= items.size
    results = build_search_results(items: items, total: total)

    searcher = double('SimilarRequests', results: results,
                                         first: [items, total > items.size])
    allow(Search).to receive(:similar).and_return(searcher)
    allow(Search.backend).to receive(:similar).and_return(searcher)
    results
  end

  # Build a Search::Results object with the given attributes
  def build_search_results(items: [], total: nil, page: 1, per_page: 25,
                           spelling_correction: nil, words_to_highlight: [],
                           has_normal_search_terms: false)
    total ||= items.size
    offset = (page - 1) * per_page

    # Convert items to the format expected by views (hash with :model key)
    # if they're not already in that format
    formatted_items = items.map do |item|
      if item.is_a?(Hash) && item.key?(:model)
        item
      else
        { model: item, percent: 100, weight: 1.0, collapse_count: 0 }
      end
    end

    Search::Results.new(
      items: formatted_items,
      total_estimate: total,
      current_page: page,
      per_page: per_page,
      offset: offset,
      spelling_correction: spelling_correction,
      words_to_highlight: words_to_highlight,
      has_normal_search_terms: has_normal_search_terms
    )
  end

  # Stub an empty search result
  def stub_empty_search_results
    stub_search_results(items: [], total: 0)
  end

  # Stub an empty typeahead result
  def stub_empty_typeahead_results
    stub_typeahead_results(items: [], total: 0)
  end
end

Search::Adapters::Xapian::Adapter.prepend(SearchHelpers::Guard)

RSpec.configure do |config|
  config.include SearchHelpers

  config.around(:each) do |example|
    SearchHelpers.stubbed = true unless example.metadata[:xapian]
    example.run
  ensure
    SearchHelpers.stubbed = false
  end
end
