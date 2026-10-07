module Search
  ##
  # The paginated request list for RequestController#list and
  # PublicBodyController#show.
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

    def initialize(filters, page, per_page, max_results)
      @filters = filters
      @page = page
      @per_page = per_page
      @max_results = max_results
    end

    # The requested page as a paginated relation. +total_entries+ counts the
    # matches up to one above +max_results+, as an exact count reads every
    # match.
    def call
      requests = filtered_requests.order(created_at: :desc)

      # Counted only when read, so a cached listing does not count.
      counter = method(:count_matches)

      requests.
        includes(:user, :outgoing_messages, public_body: :translations).
        paginate(page: @page, per_page: @per_page).
        extending do
          define_method(:total_entries) do
            @total_entries ||= counter.call(requests)
          end
        end
    end

    # A theme with its own states can prepend an override that returns
    # `super.merge(...)`.
    def status_states
      STATUS_STATES
    end

    private

    def count_matches(requests)
      # Not #count, which drops the order the planner needs to stop early.
      requests.limit(@max_results + 1).pluck(:id).size
    end

    def filtered_requests
      scope = InfoRequest.is_searchable
      scope = filter_by_public_body(scope)
      scope = filter_by_status(scope)
      scope = filter_by_dates(scope)
      scope = filter_by_tag(scope)
      filter_by_keyword(scope)
    end

    def filter_by_public_body(scope)
      public_body = @filters[:public_body]
      public_body ? scope.where(public_body: public_body) : scope
    end

    def filter_by_status(scope)
      views = Array(@filters[:latest_status]).compact
      return scope if views.empty? || (views & %w[all recent]).any?

      if views.include?('awaiting')
        return scope.where(described_state: AWAITING_STATES).
          or(scope.where(awaiting_description: true))
      end

      states = views.flat_map { |view| status_states[view] }.compact.uniq
      states.empty? ? scope : scope.where(described_state: states)
    end

    # Match requests with a searchable event in the range, as Xapian did.
    def filter_by_dates(scope)
      after = parse_date(@filters[:request_date_after])
      before = parse_date(@filters[:request_date_before])
      return scope unless after || before

      events = InfoRequestEvent.with_searchable_content.
        where(created_at: after&.beginning_of_day..before&.end_of_day)

      # No request has an event from before it was made, so this keeps the
      # same matches but lets the planner skip the newer requests.
      scope = scope.where(created_at: ..before.end_of_day) if before
      scope.where(id: events.select(:info_request_id))
    end

    def filter_by_tag(scope)
      tag = @filters[:tag]
      tag.present? ? scope.with_tag(tag) : scope
    end

    def filter_by_keyword(scope)
      query = @filters[:query].to_s.strip
      return scope if query.empty?

      # shortcut: Xapian ignores +requests+ and ranks the whole site, so a
      # narrow list can miss matches; drop this when Xapian is retired.
      ids = Search.request_search(query, requests: scope).
        results(page: 1, per_page: @max_results).
        results.map { |result| result[:model].id }
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
