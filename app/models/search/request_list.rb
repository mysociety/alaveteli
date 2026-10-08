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

    # The date picker uses the locale's format, with `/`, `-` or `.` between
    # the parts, so read either order once the separators are made `/`.
    DATE_FORMATS = %w[%d/%m/%Y %Y/%m/%d].freeze

    def initialize(filters, page, per_page, max_results)
      @filters = filters
      @page = page
      @per_page = per_page
      @max_results = max_results
    end

    def call
      scope = filtered_requests
      matches_estimated = scope.count
      requests = scope.
        order(created_at: :desc).
        offset((@page - 1) * @per_page).
        limit(@per_page).
        to_a

      { results: requests,
        matches_estimated: matches_estimated,
        show_no_more_than: [matches_estimated, @max_results].min }
    end

    private

    def filtered_requests
      scope = InfoRequest.is_searchable
      scope = filter_by_public_body(scope)
      scope = filter_by_user(scope)
      scope = filter_by_described_state(scope)
      scope = filter_by_status(scope)
      scope = filter_by_dates(scope)
      scope = filter_by_tag(scope)
      filter_by_keyword(scope)
    end

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

      if views.include?('awaiting')
        return scope.where(described_state: AWAITING_STATES).
          or(scope.where(awaiting_description: true))
      end

      states = views.flat_map { |view| STATUS_STATES[view] }.compact.uniq
      states.empty? ? scope : scope.where(described_state: states)
    end

    # Match requests with a searchable event in the range, as Xapian did.
    def filter_by_dates(scope)
      after = parse_date(@filters[:request_date_after])
      before = parse_date(@filters[:request_date_before])
      return scope unless after || before

      events = InfoRequestEvent.is_searchable.
        where(created_at: after&.beginning_of_day..before&.end_of_day)
      scope.where(id: events.select(:info_request_id))
    end

    def filter_by_tag(scope)
      tag = @filters[:tag]
      tag.present? ? scope.with_tag(tag) : scope
    end

    def filter_by_keyword(scope)
      query = @filters[:query].to_s.strip
      return scope if query.empty?

      ids = Search.request_search(query).
        results(page: 1, per_page: @max_results).
        results.map { |result| result[:model].id }
      scope.where(id: ids)
    end

    def parse_date(value)
      return if value.blank?

      value = value.tr('.-', '//')
      DATE_FORMATS.each do |format|
        return Date.strptime(value, format)
      rescue ArgumentError
        next
      end
      nil
    end
  end
end
