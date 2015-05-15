# -*- encoding : utf-8 -*-
# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'open-uri'

class GeneralController < ApplicationController

    MAX_RESULTS = 500

    # New, improved front page!
    def frontpage
        medium_cache
        @locale = self.locale_from_params()
        successful_query = InfoRequestEvent.make_query_from_params( :latest_status => ['successful'] )
        @track_thing = TrackThing.create_track_for_search_query(successful_query)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'),
                               :title => _('Successful requests'),
                               :has_json => true } ]
    end

    # Display blog entries
    def blog
        if AlaveteliConfiguration::blog_feed.empty?
            raise ActiveRecord::RecordNotFound.new("Page not enabled")
        end

        medium_cache
        @feed_autodetect = []
        @feed_url = AlaveteliConfiguration::blog_feed
        separator = @feed_url.include?('?') ? '&' : '?'
        @feed_url = "#{@feed_url}#{separator}lang=#{self.locale_from_params()}"
        @blog_items = []
        if not @feed_url.empty?
            content = quietly_try_to_open(@feed_url)
            if !content.empty?
                @data = XmlSimple.xml_in(content)
                @channel = @data['channel'][0]
                @blog_items = @channel.fetch('item') { [] }
                @feed_autodetect = [{:url => @feed_url, :title => "#{site_name} blog"}]
            end
        end
        @twitter_user = AlaveteliConfiguration::twitter_username
    end

    # Just does a redirect from ?query= search to /query
    def search_redirect
        @query = params.delete(:query)
        if @query.nil? || @query.empty?
            @query = nil
            @page = 1
            @advanced = !params[:advanced].nil?
            render :action => "search"
        else
            query_parts = @query.split("/")
            if !['bodies', 'requests', 'users', 'all'].include?(query_parts[-1])
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
        if combined.size > 0 && (['advanced'].include?(combined[-1]))
            combined.pop
            @advanced = true
        else
            @advanced = false
        end
        # TODO: currently /described isn't linked to anywhere, just used in RSS and for /list/successful
        # This is because it's confusingly different from /newest - but still useful for power users.
        if combined.size > 0 && (['newest', 'described', 'relevant'].include?(combined[-1]))
            @sort_postfix = combined.pop
            @sortby = @sort_postfix
        end
        if !params[:view].nil?
            combined += [params[:view]]
        end
        if combined.size > 0 && (['bodies', 'requests', 'users', 'all'].include?(combined[-1]))
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
        if params[:query].nil?
            params[:query] = @query
        end
        if @variety_postfix != "all" && @requests
            @query = InfoRequestEvent.make_query_from_params(params)
        end
        @inputted_sortby = @sortby
        if @sortby.nil?
            # Parse query, so can work out if it has prefix terms only - if so then it is a
            # structured query which should show newest first, rather than a free text search
            # where we want most relevant as default.
            begin
                dummy_query = ActsAsXapian::Search.new([InfoRequestEvent], @query, :limit => 1)
            rescue => e
                flash[:error] = "Your query was not quite right. " + CGI.escapeHTML(e.to_str)
                redirect_to search_url("")
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
            raise ActiveRecord::RecordNotFound.new("Sorry. No pages after #{MAX_RESULTS / requests_per_page}.")
        end

        @total_hits = @xapian_requests_hits = @xapian_bodies_hits = @xapian_users_hits = 0
        if @requests
            @xapian_requests = perform_search([InfoRequestEvent], @query, @sortby, 'request_collapse', requests_per_page)
            @requests_per_page = @per_page
            @xapian_requests_hits = @xapian_requests.results.size
            @xapian_requests_total_hits = @xapian_requests.matches_estimated
            @total_hits += @xapian_requests.matches_estimated
            @request_for_spelling = @xapian_requests
            @max_requests = (@xapian_requests.matches_estimated > MAX_RESULTS) ? MAX_RESULTS : @xapian_requests.matches_estimated
        end
        if @bodies
            @xapian_bodies = perform_search([PublicBody], @query, @sortby, nil, 5)
            @bodies_per_page = @per_page
            @xapian_bodies_hits = @xapian_bodies.results.size
            @xapian_bodies_total_hits = @xapian_bodies.matches_estimated
            @total_hits += @xapian_bodies.matches_estimated
            @request_for_spelling = @xapian_bodies
            @max_bodies = (@xapian_bodies.matches_estimated > MAX_RESULTS) ? MAX_RESULTS : @xapian_bodies.matches_estimated
        end
        if @users
            @xapian_users = perform_search([User], @query, @sortby, nil, 5)
            @users_per_page = @per_page
            @xapian_users_hits = @xapian_users.results.size
            @xapian_users_total_hits = @xapian_users.matches_estimated
            @total_hits += @xapian_users.matches_estimated
            @request_for_spelling = @xapian_users
            @max_users = (@xapian_users.matches_estimated > MAX_RESULTS) ? MAX_RESULTS : @xapian_users.matches_estimated
        end

        # Spelling and highight words are same for all three queries
        @highlight_words = @request_for_spelling.words_to_highlight(:regex => true, :include_original => true)
        if !(@request_for_spelling.spelling_correction =~ /[a-z]+:/)
            @spelling_correction = @request_for_spelling.spelling_correction
        end

        @track_thing = TrackThing.create_track_for_search_query(@query, @variety_postfix)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]
    end

    # Handle requests for non-existent URLs - will be handled by ApplicationController::render_exception
    def not_found
        raise RouteNotFound
    end

    def version
        respond_to do |format|
            format.json { render :json => {
                :alaveteli_git_commit => alaveteli_git_commit,
                :alaveteli_version => ALAVETELI_VERSION,
                :ruby_version => RUBY_VERSION,
                :visible_request_count => InfoRequest.visible.count,
                :confirmed_user_count => User.where(:email_confirmed => true).count
            }}
        end
    end
end

