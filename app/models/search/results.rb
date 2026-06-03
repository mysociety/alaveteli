module Search
  ##
  # A collection class for search results that provides a common interface
  # for handling paginated search results with metadata.
  #
  class Results
    include Enumerable

    attr_reader :items, :total_estimate, :current_page, :per_page, :offset,
                :spelling_correction

    # Compatibility aliases with ActsAsXapian search
    alias matches_estimated total_estimate
    alias results items

    def initialize(items:, total_estimate:, current_page: 1, per_page: 10,
                   offset: 0, spelling_correction: nil, words_to_highlight: [],
                   has_normal_search_terms: false)
      @items = Array(items)
      @total_estimate = total_estimate.to_i
      @current_page = current_page.to_i
      @per_page = per_page.to_i
      @offset = offset.to_i
      @spelling_correction = spelling_correction
      @words_to_highlight = Array(words_to_highlight)
      @has_normal_search_terms = has_normal_search_terms
    end

    def has_normal_search_terms?
      @has_normal_search_terms
    end

    # Returns words to highlight in search results.
    # Accepts options for compatibility but returns pre-computed words.
    def words_to_highlight(_opts = {})
      @words_to_highlight
    end

    # Enumerable interface - delegate to items
    def each(&block)
      items.each(&block)
    end

    # Collection query methods.
    # any?, count and first come from Enumerable via #each.
    def empty?
      items.empty?
    end

    # TODO: Remove once callers are updated to not rely on #present?
    # Preserves old ActsAsXapian behaviour where search objects were always
    # present regardless of result count.
    def present? = true

    def size
      items.size
    end

    def length
      items.length
    end

    def last
      items.last
    end

    # Pagination helper methods
    def has_more?
      total_estimate > (offset + size)
    end

    def has_previous?
      current_page > 1
    end

    def next_page
      has_more? ? current_page + 1 : nil
    end

    def previous_page
      has_previous? ? current_page - 1 : nil
    end

    def total_pages
      return 1 if per_page <= 0

      (total_estimate / per_page.to_f).ceil
    end

    def first_item_number
      return 0 if empty?

      offset + 1
    end

    def last_item_number
      return 0 if empty?

      offset + size
    end

    # For compatibility with existing views that expect array-like behavior
    def to_a
      items.to_a
    end

    # String representation for debugging
    def to_s
      "SearchResults(#{size}/#{total_estimate} items, page #{current_page})"
    end

    def inspect
      "#<#{self.class.name} items=#{size}, total_estimate=#{total_estimate}, " \
      "current_page=#{current_page}, per_page=#{per_page}>"
    end
  end
end
