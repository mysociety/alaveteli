# app/controllers/general_controller.rb:
# For pages like front page, general search, that aren't specific to a
# particular model.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: general_controller.rb,v 1.23 2008-05-15 17:40:43 francis Exp $

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
        query = 'variety:response (status:successful OR status:partially_successful)'
        sortby = "newest"
        @xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_collapse', 3)
    end


    # Just does a redirect from ?query= search to /query
    def search_redirect
        @query = params[:query]
        @sortby = params[:sortby]
        if @query.nil? or @query.empty?
            @query = nil
            render :action => "search"
        else
            redirect_to search_url(@query, @sortby)
        end
    end

    # Actual search
    def search
        # XXX Why is this so complicated with arrays and stuff? Look at the route
        # in config/routes.rb for comments.
        combined = params[:combined]
        sortby = nil
        if combined.size > 1 and combined[-1] == 'newest'
            sortby = 'newest'
            combined = combined[0..-2]
        end
        query = combined.join("/")

        # Query each type separately for separate display
        @xapian_requests = perform_search([InfoRequestEvent], query, sortby, 'request_collapse', 25)
        @xapian_bodies = perform_search([PublicBody], query, sortby, nil, 5)
        @xapian_users = perform_search([User], query, sortby, nil, 5)

        @total_hits = @xapian_requests.matches_estimated + @xapian_bodies.matches_estimated + @xapian_users.matches_estimated

        # Spelling and highight words are same for all three queries
        @spelling_correction = @xapian_requests.spelling_correction
        @highlight_words = @xapian_requests.words_to_highlight
    end

    # For debugging
    def fai_test
        sleep 10
        render :text => "awake\n"
    end

    private

    # Used in front page search for public body
    def public_body_query(query)
        # XXX try using search now we have spell correction?

        criteria = '%' + query + '%'
        @public_bodies = PublicBody.find(:all, 
                    :conditions => ["name ilike ? or short_name ilike ?", criteria, criteria],
                    :order => 'name', :limit=>10)  
        return @public_bodies
    end

end
 
