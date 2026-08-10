# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class GeneralController < ApplicationController
  MAX_RESULTS = 500

  skip_before_action :html_response, only: :version

  before_action :redirect_pros_to_dashboard, only: :frontpage

  # New, improved front page!
  def frontpage
    medium_cache
    @locale = AlaveteliLocalization.locale
    successful_query = InfoRequestEvent.make_query_from_params( latest_status: ['successful'] )
    @request_events = InfoRequest.recent_requests
    @track_thing = TrackThing.create_track_for_search_query(successful_query)
    @number_of_requests = Rails.cache.fetch(
      'frontpage/info_request_count', expires_in: 1.hour
    ) { InfoRequest.is_searchable.count }
    @number_of_authorities = PublicBody.visible.count
    @feed_autodetect = [ { url: do_track_url(@track_thing, 'feed'),
                           title: _('Successful requests'),
                           has_json: true } ]
  end

  # Display blog entries
  def blog
    raise(ActiveRecord::RecordNotFound, "Page not enabled") unless Blog.enabled?

    medium_cache
    @blog = Blog.new
    @feed_autodetect = @blog.feeds
  end

  # Just does a redirect from ?query= search to /query
  def search_redirect
    @query = params.delete(:query)
    if @query.nil? || @query.empty?
      @query = nil
      @page = 1
      @advanced = !params[:advanced].nil?
      render action: "search"
    else
      query_parts = @query.split("/")
      if !%w[bodies requests users all].include?(query_parts[-1])
        redirect_to search_url([@query, "all"], params)
      else
        redirect_to search_url(@query, params)
      end
    end
  end

  # Actual search
  def search
    # TODO: Why is this so complicated with arrays and stuff? Look at the route
    # in config/routes.rb for comments.

    combined = params[:combined].split("/")
    @sortby = nil
    @bodies = @requests = @users = true
    if combined.size > 0 && ['advanced'].include?(combined[-1])
      combined.pop
      @advanced = true
    else
      @advanced = false
    end
    # TODO: currently /described isn't linked to anywhere, just used in RSS and for /list/successful
    # This is because it's confusingly different from /newest - but still useful for power users.
    if combined.size > 0 && %w[newest described relevant].include?(combined[-1])
      @sort_postfix = combined.pop
      @sortby = @sort_postfix
    end
    combined += [params[:view]] unless params[:view].nil?
    if combined.size > 0 && %w[bodies requests users all].include?(combined[-1])
      @variety_postfix = combined.pop
      case @variety_postfix
      when 'bodies'
        @bodies = true
        @requests = false
        @users = false
      when 'requests'
        @bodies = false
        @requests = true
        @users = false
      when 'users'
        @bodies = false
        @requests = false
        @users = true
      else
        @variety_postfix = "all"
      end
    end
    @query = combined.join("/")
    params[:query] = @query if params[:query].nil?
    if @variety_postfix != "all" && @requests
      @query = InfoRequestEvent.make_query_from_params(params)
    end
    @inputted_sortby = @sortby
    if @sortby.nil?
      # Parse query, so can work out if it has prefix terms only - if so then it is a
      # structured query which should show newest first, rather than a free text search
      # where we want most relevant as default.
      begin
        dummy_query = Search.search(@query, models: [InfoRequestEvent]).
                       results(page: 1, per_page: 1)
      rescue => e
        redirect_to search_url(""),
                    error: "Your query was not quite right. #{e.message}"
        return
      end
      if dummy_query.has_normal_search_terms?
        @sortby = 'relevant'
      else
        @sortby = 'newest'
      end
    end

    @page = get_search_page_from_params

    # Query each type separately for separate display (TODO: we are calling
    # perform_search multiple times and it clobbers per_page for each one,
    # so set as separate var)
    requests_per_page = params[:requests_per_page] ? params[:requests_per_page].to_i : 25

    # Later pages are very expensive to load
    if @page > MAX_RESULTS / requests_per_page
      raise ActiveRecord::RecordNotFound, "Sorry. No pages after #{MAX_RESULTS / requests_per_page}."
    end

    @request_result_count = @body_result_count = @user_result_count = 0
    @total_hits = 0
    if @requests
      @request_results = perform_search(
        [InfoRequestEvent], @query, @sortby,
        'request_collapse', requests_per_page
      )
      @requests_per_page = @per_page
      @request_result_count = @request_results.results.size
      @request_total_count = @request_results.matches_estimated
      @total_hits += @request_results.matches_estimated
      @request_for_spelling = @request_results
      @max_requests = [@request_results.matches_estimated,
                       MAX_RESULTS].min
    end
    if @bodies
      @body_results = perform_search([PublicBody], @query, @sortby, nil, 5)
      @bodies_per_page = @per_page
      @body_result_count = @body_results.results.size
      @body_total_count = @body_results.matches_estimated
      @total_hits += @body_results.matches_estimated
      @request_for_spelling = @body_results
      @max_bodies = [@body_results.matches_estimated,
                     MAX_RESULTS].min
    end
    if @users
      @user_results = perform_search([User], @query, @sortby, nil, 5)
      @users_per_page = @per_page
      @user_result_count = @user_results.results.size
      @user_total_count = @user_results.matches_estimated
      @total_hits += @user_results.matches_estimated
      @request_for_spelling = @user_results
      @max_users = [@user_results.matches_estimated,
                    MAX_RESULTS].min
    end

    # Spelling and highlight words are same for all three queries
    @highlight_words = @request_for_spelling.words_to_highlight(regex: true, include_original: true)
    unless @request_for_spelling.spelling_correction =~ /[a-z]+:/
      @spelling_correction = @request_for_spelling.spelling_correction
    end

    @track_thing = TrackThing.create_track_for_search_query(@query, @variety_postfix)
    @feed_autodetect = [ { url: do_track_url(@track_thing, 'feed'), title: @track_thing.params[:title_in_rss], has_json: true } ]
  end

  # Handle requests for non-existent URLs - will be handled by ApplicationController::render_exception
  def not_found
    raise RouteNotFound
  end

  def version
    respond_to do |format|
      format.json { render json: Statistics::General.new }
    end
  end

  private

  def redirect_pros_to_dashboard
    if feature_enabled?(:alaveteli_pro) && current_user && current_user.is_pro?
      redirect_to alaveteli_pro_dashboard_path
    end
  end
end
