class TypeaheadSearch

  attr_accessor :query, :model, :page, :per_page, :wildcard, :run_search

  def initialize(query, opts = {})
    @query = query
    @model = opts.fetch(:model)
    @page = opts.fetch(:page, 1)
    @per_page = opts.fetch(:per_page, 25)
    @exclude_tags = opts.fetch(:exclude_tags, [])
    @wildcard = true
    @run_search = true
  end

  def xapian_search
    check_query
    return nil unless @run_search
    ActsAsXapian.readable_init
    old_default_op = ActsAsXapian.query_parser.default_op
    ActsAsXapian.query_parser.default_op = Xapian::Query::OP_OR
    begin
      xapian_search = run_query
    rescue RuntimeError => e
      if e.message =~ /^QueryParserError: Wildcard/
        # Wildcard expands to too many terms
        Rails.logger.info "Wildcard query '#{query}' caused: #{e.message.force_encoding('UTF-8')}"
        @wildcard = false
        xapian_search = run_query
      end
    end
    ActsAsXapian.query_parser.default_op = old_default_op
    xapian_search
  end

  def options
    {
      :offset => (@page - 1) * @per_page,
      :limit => @per_page,
      :sort_by_prefix => nil,
      :sort_by_ascending => true,
      :collapse_by_prefix => collapse?,
      :wildcard => @wildcard,
      :model => @model
    }
  end

  private

  def check_query
    @query = @query.strip
    # don't wildcard search a short end word
    query_words = @query.split
    if query_words.last && query_words.last.strip.length < 3
      query_words.pop
      @query = query_words.join
      @wildcard = false
    end

    # don't run a search if there's no query
    if @query.blank?
      @run_search = false
    end

  end

  def run_query
    user_query = ActsAsXapian.query_parser.parse_query(prepared_query, flags)
    ActsAsXapian::Search.new([@model], @query, options, user_query)
  end

  def flags
    if @wildcard
      default_flags | Xapian::QueryParser::FLAG_WILDCARD
    else
      default_flags
    end
  end

  def default_flags
    Xapian::QueryParser::FLAG_LOVEHATE |
    Xapian::QueryParser::FLAG_SPELLING_CORRECTION
  end

  def prepared_query
    # Since acts_as_xapian doesn't support the Partial match flag, we work around it
    # by making the last word a wildcard, which is quite the same
    query = if @wildcard
      "#{@query.strip}*"
    else
      @query
    end
    if @exclude_tags
      tag_string = @exclude_tags.map{|tag| "-tag:#{tag}"}.join(" ")
      query = "#{query} #{tag_string}"
    end
    query
  end

  def collapse?
    if @model == PublicBody
      nil
    elsif @model == InfoRequestEvent
      'request_collapse'
    end
  end

end
