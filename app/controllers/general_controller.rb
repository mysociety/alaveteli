# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: general_controller.rb,v 1.57 2009-10-03 10:23:43 francis Exp $

require 'xmlsimple'
require 'open-uri'

class GeneralController < ApplicationController

    # New, improved front page!
    def frontpage
        # This is too slow
        #@popular_bodies = PublicBody.find(:all, :select => "*, (select count(*) from info_requests where info_requests.public_body_id = public_bodies.id) as c", :order => "c desc", :limit => 32)

        # Just hardcode some popular authorities for now
        # ('tgq', 'atbra' is for debugging on Francis's development environment)
        @popular_bodies = PublicBody.find(:all, :conditions => ["url_name in (
              'bbc', 
              'dwp', 
              'dh', 
              'snh',
              'royal_mail_group', 
              'mod', 
              'kent_county_council', 
              'wirral_borough_council'
              /* , 'tgq', 'atbra' */
        )"]).sort_by { |pb| pb.url_name }.reverse # just an order that looks better

        # Get some successful requests #
        begin
            query = 'variety:response (status:successful OR status:partially_successful)'
            # query = 'variety:response' # XXX debug
            sortby = "described"
            @xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_title_collapse', 8)
            @successful_request_events = @xapian_object.results.map { |r| r[:model] }
            @successful_request_events = @successful_request_events.sort_by { |e| e.described_at }.reverse
        rescue
            @successful_request_events = []
        end

        cache_in_squid
    end

    # Display WhatDoTheyKnow category from mySociety blog
    def blog
        feed_url = 'http://www.mysociety.org/category/projects/whatdotheyknow/feed/'
        all_url = 'http://www.mysociety.org/category/projects/whatdotheyknow/'
        @output = ''
        content = open(feed_url).read
        @data = XmlSimple.xml_in(content)
        @channel = @data['channel'][0]
        @items = @channel['item']

        @feed_autodetect = [ { :url => @channel['link'][0]['href'], :title => "WhatDoTheyKnow blog"} ]
    end

    # Just does a redirect from ?query= search to /query
    def search_redirect
        @query = params[:query]
        @sortby = params[:sortby]
        @bodies = params[:bodies]
        if @query.nil? || @query.empty?
            @query = nil
            @page = 1
            render :action => "search"
        else
            if (@bodies == '1') && (@sortby.nil? || @sortby.empty?)
                @postfix = 'bodies'
            else
                @postfix = @sortby
            end
            redirect_to search_url(@query, @postfix)
        end
    end

    # Actual search
    def search
        # XXX Why is this so complicated with arrays and stuff? Look at the route
        # in config/routes.rb for comments.
        combined = params[:combined]
        @sortby = nil
        @bodies = false # searching from front page, largely for a public authority
        # XXX currently /described isn't linked to anywhere, just used in RSS and for /list/successful
        # This is because it's confusingly different from /newest - but still useful for power users.
        if combined.size > 1 && (['newest', 'described', 'bodies', 'relevant'].include?(combined[-1]))
            @postfix = combined[-1]
            combined = combined[0..-2]
            if @postfix == 'bodies'
                @bodies = true
            else
                @sortby = @postfix
            end
        end
        @query = combined.join("/")

        @inputted_sortby = @sortby
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
        requests_per_page = params[:requests_per_page].to_i || 25;
        @xapian_requests = perform_search([InfoRequestEvent], @query, @sortby, 'request_collapse', requests_per_page)
        @requests_per_page = @per_page
        @xapian_bodies = perform_search([PublicBody], @query, @sortby, nil, 5)
        @bodies_per_page = @per_page
        @xapian_users = perform_search([User], @query, @sortby, nil, 5)
        @users_per_page = @per_page

        @this_page_hits = @xapian_requests.results.size + @xapian_bodies.results.size + @xapian_users.results.size
        @total_hits = @xapian_requests.matches_estimated + @xapian_bodies.matches_estimated + @xapian_users.matches_estimated

        # Spelling and highight words are same for all three queries
        @spelling_correction = @xapian_requests.spelling_correction
        @highlight_words = @xapian_requests.words_to_highlight

        @track_thing = TrackThing.create_track_for_search_query(@query)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
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

end
 
