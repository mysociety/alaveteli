# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: general_controller.rb,v 1.7 2008-03-10 12:24:10 francis Exp $

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
                redirect_to new_request_to_body_url(:public_body_id => @public_body.id.to_s)
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
        if @query.nil?
            render :action => "search"
        else
            redirect_to search_url(:query => @query)
        end
    end

    # Actual search
    def search
        @per_page = 20
        @query = params[:query].join("/")

        # Used for simpler word highlighting view code for users and public bodies
        query_nopunc = @query.gsub(/[^a-z0-9]/i, " ")
        query_nopunc = query_nopunc.gsub(/\s+/, " ")
        @highlight_words = query_nopunc.split(" ")

        @solr_object = InfoRequest.multi_solr_search(@query, :models => [ OutgoingMessage, IncomingMessage, PublicBody, User ],
            :limit => @per_page, :offset => ((params[:page]||"1").to_i-1) * @per_page, 
            :highlight => { 
                :prefix => '<span class="highlight">',
                :suffix => '</span>',
                :fragsize => 250,
                :fields => ["title", "initial_request_text", # InfoRequest
                           "body", # OutgoingMessage 
                           "get_text_for_indexing", # IncomingMessage
                           "name", "short_name", # PublicBody
                           "name" # User
            ]}
        )
        @search_results = @solr_object.results

        # Extract better Solr highlighting for info request related results
        @highlighting = @solr_object.highlights
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
 
