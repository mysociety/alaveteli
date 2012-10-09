# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

begin
  require 'xmlsimple'
rescue LoadError
  # Debian maintainers put their xmlsimple in a different location :(
  require 'lib/xmlsimple'
end

require 'open-uri'

class GeneralController < ApplicationController

    # New, improved front page!
    def frontpage
        medium_cache
        behavior_cache :tag => [session[:user_id], request.url] do
            # get some example searches and public bodies to display
            # either from config, or based on a (slow!) query if not set
            body_short_names = Configuration::frontpage_publicbody_examples.split(/\s*;\s*/).map{|s| "'%s'" % s.gsub(/'/, "''") }.join(", ")
            @locale = self.locale_from_params()
            locale_condition = 'public_body_translations.locale = ?'
            conditions = [locale_condition, @locale]
            PublicBody.with_locale(@locale) do
                if body_short_names.empty?
                    # This is too slow
                    @popular_bodies = PublicBody.find(:all,
                        :order => "info_requests_count desc",
                        :limit => 32,
                        :conditions => conditions,
                        :joins => :translations
                    )
                else
                    conditions[0] += " and public_bodies.url_name in (" + body_short_names + ")"
                    @popular_bodies = PublicBody.find(:all,
                         :conditions => conditions,
                         :joins => :translations)
                end
            end
            # Get some successful requests
            begin
                query = 'variety:response (status:successful OR status:partially_successful)'
                sortby = "newest"
                max_count = 5
                xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_title_collapse', max_count)
                @request_events = xapian_object.results.map { |r| r[:model] }

                # If there are not yet enough successful requests, fill out the list with
                # other requests
                if @request_events.count < max_count
                    @request_events_all_successful = false
                    query = 'variety:sent'
                    xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_title_collapse', max_count-@request_events.count)
                    more_events = xapian_object.results.map { |r| r[:model] }
                    @request_events += more_events
                else
                    @request_events_all_successful = true
                end
            rescue
                @request_events = []
            end
        end
    end

    # Display blog entries
    def blog
        medium_cache
        @feed_autodetect = []
        @feed_url = "#{Configuration::blog_feed}?lang=#{self.locale_from_params()}"
        @blog_items = []
        if not @feed_url.empty?
            content = quietly_try_to_open(@feed_url)
            if !content.empty?
                @data = XmlSimple.xml_in(content)
                @channel = @data['channel'][0]
                @blog_items = @channel['item']
                @feed_autodetect = [{:url => @feed_url, :title => "#{site_name} blog"}]
            end
        end
        @twitter_user = Configuration::twitter_username
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
        # XXX Why is this so complicated with arrays and stuff? Look at the route
        # in config/routes.rb for comments.
        combined = params[:combined]
        @sortby = nil
        @bodies = @requests = @users = true
        if combined.size > 0 && (['advanced'].include?(combined[-1]))
            combined.pop
            @advanced = true
        else
            @advanced = false
        end
        # XXX currently /described isn't linked to anywhere, just used in RSS and for /list/successful
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
            @query, _ = make_query_from_params
        end
        @inputted_sortby = @sortby
        @common_query = get_tags_from_params
        if @sortby.nil?
            # Parse query, so can work out if it has prefix terms only - if so then it is a
            # structured query which should show newest first, rather than a free text search
            # where we want most relevant as default.
            begin
                dummy_query = ::ActsAsXapian::Search.new([InfoRequestEvent], @query, :limit => 1)
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

        # Query each type separately for separate display (XXX we are calling
        # perform_search multiple times and it clobbers per_page for each one,
        # so set as separate var)
        requests_per_page = 25
        if params[:requests_per_page]
            requests_per_page = params[:requests_per_page].to_i
        end
        @this_page_hits = @total_hits = @xapian_requests_hits = @xapian_bodies_hits = @xapian_users_hits = 0
        if @requests
            @xapian_requests = perform_search([InfoRequestEvent], @query, @sortby, 'request_collapse', requests_per_page)
            @requests_per_page = @per_page
            @this_page_hits += @xapian_requests.results.size
            @xapian_requests_hits = @xapian_requests.results.size
            @xapian_requests_total_hits = @xapian_requests.matches_estimated
            @total_hits += @xapian_requests.matches_estimated
        end
        if @bodies
            @xapian_bodies = perform_search([PublicBody], @query, @sortby, nil, 5)
            @bodies_per_page = @per_page
            @this_page_hits += @xapian_bodies.results.size
            @xapian_bodies_hits = @xapian_bodies.results.size
            @xapian_bodies_total_hits = @xapian_bodies.matches_estimated
            @total_hits += @xapian_bodies.matches_estimated
        end
        if @users
            @xapian_users = perform_search([User], @query, @sortby, nil, 5)
            @users_per_page = @per_page
            @this_page_hits += @xapian_users.results.size
            @xapian_users_hits = @xapian_users.results.size
            @xapian_users_total_hits = @xapian_users.matches_estimated
            @total_hits += @xapian_users.matches_estimated
        end

        # Spelling and highight words are same for all three queries
        if !@xapian_requests.nil?
            @highlight_words = @xapian_requests.words_to_highlight
            if !(@xapian_requests.spelling_correction =~ /[a-z]+:/)
                @spelling_correction = @xapian_requests.spelling_correction
            end
        end

        @track_thing = TrackThing.create_track_for_search_query(@query, @variety_postfix)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]
    end

    # Jump to a random request
    def random_request
        info_request = InfoRequest.random
        redirect_to request_url(info_request)
    end

    # For debugging
    def fai_test
        sleep 10
        render :text => "awake\n"
    end

    def custom_css
        long_cache
        @locale = self.locale_from_params()
        render(:layout => false, :content_type => 'text/css')
    end


end

