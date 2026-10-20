module Search
  ##
  # The paginated request list for RequestController#list, and the request
  # lists on authority and user pages.
  #
  # The list is a filtered listing rather than a keyword search: status, date
  # and tag filters are applied as database conditions on InfoRequest (which
  # works under any backend). Only a free-text +query+ goes through the search
  # index, via Search.request_search, and restricts the listing to the
  # requests it matches.
  #
  class RequestList
    # Map a request-list status view to the described_state values it covers.
    STATUS_STATES = {
      'successful' => %w[successful partially_successful],
      'unsuccessful' => %w[rejected not_held],
      'internal_review' => %w[internal_review],
      'gone_postal' => %w[gone_postal],
      'other' => %w[gone_postal error_message requires_admin user_withdrawn]
    }.freeze

    # 'awaiting' also matches requests still awaiting classification.
    AWAITING_STATES = %w[
      waiting_response waiting_clarification internal_review
      gone_postal error_message requires_admin
    ].freeze

    # Map a request variety to the event types it covers.
    VARIETY_EVENT_TYPES = {
      'sent' => %w[sent followup_sent],
      'response' => %w[response],
      'comment' => %w[comment]
    }.freeze

    def initialize(filters, page = 1, per_page = 25, max_results = nil)
      @filters = filters
      @page = page
      @per_page = per_page
      @max_results = max_results
    end

    # The requested page as a paginated relation; +total_entries+ counts
    # every match.
    def call
      requests.
        includes(:user, :outgoing_messages, public_body: :translations).
        order(created_at: :desc).
        paginate(page: @page, per_page: @per_page)
    end

    # A theme with its own states can prepend an override that returns
    # `super.merge(...)`.
    def status_states
      STATUS_STATES
    end

    # Every matching request, as an unordered relation.
    def requests
      scope = InfoRequest.is_searchable
      scope = filter_by_public_body(scope)
      scope = filter_by_user(scope)
      scope = filter_by_described_state(scope)
      scope = filter_by_status(scope)
      scope = filter_by_events(scope)
      scope = filter_by_tag(scope)
      filter_by_keyword(scope)
    end

    private

    def filter_by_public_body(scope)
      public_body = @filters[:public_body]
      public_body ? scope.where(public_body: public_body) : scope
    end

    def filter_by_user(scope)
      user = @filters[:user]
      user ? scope.where(user: user) : scope
    end

    def filter_by_described_state(scope)
      state = @filters[:described_state]
      state.present? ? scope.where(described_state: state) : scope
    end

    def filter_by_status(scope)
      views = Array(@filters[:latest_status]).compact
      return scope if views.empty? || (views & %w[all recent]).any?

      states = views.flat_map { |view| status_states[view] }.compact.uniq
      if views.include?('awaiting')
        scope.where(described_state: states | AWAITING_STATES).
          or(scope.where(awaiting_description: true))
      elsif states.any?
        scope.where(described_state: states)
      else
        scope
      end
    end

    # Match requests with one searchable event in the range and of a chosen
    # variety, as Xapian did.
    def filter_by_events(scope)
      after = parse_date(@filters[:request_date_after])
      before = parse_date(@filters[:request_date_before])

      varieties = Array(@filters[:request_variety])
      varieties = [] if (VARIETY_EVENT_TYPES.keys - varieties).empty?
      types = VARIETY_EVENT_TYPES.values_at(*varieties).flatten.compact

      return scope unless after || before || types.any?

      events = InfoRequestEvent.is_searchable
      if after || before
        events = events.
          where(created_at: after&.beginning_of_day..before&.end_of_day)
      end
      events = events.where(event_type: types) if types.any?
      scope.where(id: events.select(:info_request_id))
    end

    def filter_by_tag(scope)
      tag = @filters[:tag]
      tag.present? ? scope.with_tag(tag) : scope
    end

    def filter_by_keyword(scope)
      query = @filters[:query].to_s.strip
      return scope if query.empty?

      # Xapian ignores +requests+ and ranks the whole site, so a narrow list
      # can miss matches; drop this when Xapian is retired.
      ids = Search.request_search(query, requests: scope).ids(@max_results)
      scope.where(id: ids)
    end

    # The date picker sends the locale's date format with `/` for `-`, so
    # read that, then ISO 8601 or day first, once the separators are `/`.
    def parse_date(value)
      return if value.blank?

      value = value.tr('.-', '//')
      [I18n.t('date.formats.default'), '%Y-%m-%d', '%d-%m-%Y'].each do |format|
        date = Date.strptime(value, format.tr('.-', '//'))
        # %Y reads the day of a day-first date as a year without error.
        return date if date.year >= 1000
      rescue ArgumentError
        next
      end
      nil
    end
  end
end
