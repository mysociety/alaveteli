##
# Helper methods for stubbing search in tests.
#
# Stubs ActsAsXapian and TypeaheadSearch so specs can run without a
# Xapian search index.
#
# Usage in specs:
#   it 'searches for bodies' do
#     stub_search_results(items: [public_body], total: 1)
#     # or for typeahead:
#     stub_typeahead_results(items: [public_body], total: 1)
#   end
#
module SearchHelpers
  ##
  # Lightweight stand-in for ActsAsXapian search results.
  #
  class NullSearchResult
    DEFAULTS = {
      results: [], matches_estimated: 0, spelling_correction: nil,
      words_to_highlight: [], has_normal_search_terms?: false,
      present?: true, blank?: false
    }.freeze

    def xapian_search
      self
    end

    def method_missing(name, *, **)
      DEFAULTS.fetch(name) { super }
    end

    def respond_to_missing?(name, include_private = false)
      DEFAULTS.key?(name) || super
    end
  end

  ##
  # Guard prepended onto search class .new methods. When the global stub flag
  # is set it returns a null object, avoiding any Xapian database access.
  #
  module Guard
    def new(*, **)
      SearchHelpers.stubbed? ? SearchHelpers::NullSearchResult.new : super
    end
  end

  def self.stubbed?
    Thread.current[:search_helpers_stubbed]
  end

  def self.stubbed=(value)
    Thread.current[:search_helpers_stubbed] = value
  end

  # Stub ActsAsXapian::Search.new to return results
  def stub_search_results(items: [], total: nil, spelling_correction: nil,
                          words_to_highlight: [], has_normal_search_terms: true)
    total ||= items.size
    result = build_search_results(
      items: items,
      total: total,
      spelling_correction: spelling_correction,
      words_to_highlight: words_to_highlight,
      has_normal_search_terms: has_normal_search_terms
    )
    allow(ActsAsXapian::Search).to receive(:new).and_return(result)
    result
  end

  # Stub TypeaheadSearch to return results
  def stub_typeahead_results(items: [], total: nil, spelling_correction: nil,
                             words_to_highlight: [])
    total ||= items.size
    result = build_search_results(
      items: items,
      total: total,
      spelling_correction: spelling_correction,
      words_to_highlight: words_to_highlight
    )
    typeahead = double('TypeaheadSearch', xapian_search: result)
    allow(TypeaheadSearch).to receive(:new).and_return(typeahead)
    result
  end

  # Stub ActsAsXapian::Similar.new to return results
  def stub_similar_requests(items: [], total: nil)
    total ||= items.size
    build_search_results(items: items, total: total).tap do |result|
      allow(ActsAsXapian::Similar).to receive(:new).and_return(result)
    end
  end

  # Build a double mimicking an ActsAsXapian search result object
  def build_search_results(items: [], total: nil, spelling_correction: nil,
                           words_to_highlight: [],
                           has_normal_search_terms: false)
    total ||= items.size

    formatted_items = items.map do |item|
      if item.is_a?(Hash) && item.key?(:model)
        item
      else
        { model: item, percent: 100, weight: 1.0, collapse_count: 0 }
      end
    end

    double('XapianResult',
           results: formatted_items,
           matches_estimated: total,
           spelling_correction: spelling_correction,
           words_to_highlight: words_to_highlight,
           has_normal_search_terms?: has_normal_search_terms,
           present?: true,
           blank?: false)
  end
end

ActsAsXapian::Search.singleton_class.prepend(SearchHelpers::Guard)
ActsAsXapian::Similar.singleton_class.prepend(SearchHelpers::Guard)
TypeaheadSearch.singleton_class.prepend(SearchHelpers::Guard)

RSpec.configure do |config|
  config.include SearchHelpers

  # Prevent any Xapian database access in non-xapian tests. Uses an
  # around hook so the guard is active before spec-level around hooks
  # that may trigger searches (e.g. integration test login helpers).
  config.around(:each) do |example|
    SearchHelpers.stubbed = true unless example.metadata[:xapian]
    example.run
  ensure
    SearchHelpers.stubbed = false
  end
end
