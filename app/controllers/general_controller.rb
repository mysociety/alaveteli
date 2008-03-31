# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: general_controller.rb,v 1.12 2008-03-31 17:38:10 francis Exp $

class GeneralController < ApplicationController

    # Fancy javascript smancy for auto complete search on front page
    def auto_complete_for_public_body_query
        @public_bodies = public_body_query(params[:public_body][:query])

        render :partial => "public_body_query"
    end

    # Actual front page
    def frontpage
        # Public body search on the left
        @public_bodies = []
        @query_made = false
        if params[:public_body] and params[:public_body][:query]
            # Try and do exact match - redirect if it is made
            @public_body = PublicBody.find_by_name(params[:public_body][:query])
            if not @public_body.nil?
                redirect_to public_body_url(@public_body)
            end
            # Otherwise use search engine to find public body
            @public_bodies = public_body_query(params[:public_body][:query])
            @query_made = true
        end

        # Get all successful requests for display on the right  
        @info_requests = InfoRequest.find :all, :order => "created_at desc", :conditions => "prominence = 'normal' and described_state in ('successful', 'partially_successful')", :limit => 3
    end


    # Just does a redirect from ?query= search to /query
    def search_redirect
        @query = params[:query]
        @sortby = params[:sortby]
        if @query.empty?
            @query = nil
            render :action => "search"
        else
            redirect_to search_url(:query => @query, :sortby => @sortby)
        end
    end

    # Actual search
    def search
        @per_page = 20
        @query = params[:query]
        @sortby = params[:sortby]
        @page = (params[:page] || "1").to_i

        # Work out sorting method
        if @sortby.nil?
            order = nil
        elsif @sortby == 'newest'
            order = 'created_at desc'
        else
            raise "Unknown sort order " + @sortby
        end

        # Peform the search
        solr_object = InfoRequestEvent.multi_solr_search(@query, :models => [ PublicBody, User ],
            :limit => @per_page, :offset => (@page - 1) * @per_page, 
            :highlight => { 
                :prefix => '<span class="highlight">',
                :suffix => '</span>',
                :fragsize => 250,
                :fields => ["solr_text_main", "title", # InfoRequestEvent
                           "name", "short_name", # PublicBody
                           "name" # User
            ]}, :order => order
        )
        @search_results = solr_object.results
        @search_hits = solr_object.total_hits

        # Calculate simple word highlighting view code for users and public bodies
        query_nopunc = @query.gsub(/[^a-z0-9]/i, " ")
        query_nopunc = query_nopunc.gsub(/\s+/, " ")
        @highlight_words = query_nopunc.split(" ")

        # Extract better Solr highlighting for info request related results
        @highlighting = solr_object.highlights
    end
 
    def fai_test
        sleep 10
        render :text => "awake\n"
    end

    private

    # Used in front page search for public body
    def public_body_query(query)
        # @public_bodies = PublicBody.find_by_solr(query).results

        criteria = '%' + query + '%'
        @public_bodies = PublicBody.find(:all, 
                    :conditions => ["name ilike ? or short_name ilike ?", criteria, criteria],
                    :order => 'name', :limit=>10)  
        return @public_bodies
    end

end
 
