# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: general_controller.rb,v 1.2 2008-03-06 20:10:29 francis Exp $

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
        query = params[:query]
        redirect_to search_url(:query => query)
    end

    # Actual search
    def search
        @per_page = 20
        query = params[:query]
        @solr_object = InfoRequest.multi_solr_search(query, :models => [ OutgoingMessage, IncomingMessage ],
            :limit => @per_page, :offset => ((params[:page]||"1").to_i-1) * @per_page)
        @search_results = @solr_object.results
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
 
