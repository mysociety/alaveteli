# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.42 2008-04-30 00:46:00 francis Exp $


class ApplicationController < ActionController::Base
    # Standard hearders, footers and navigation for whole site
    layout "default"

    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_foi_session_id'

    # Override default error handler
    def rescue_action_in_public(exception)
        # do something based on exception
        @exception_backtrace = exception.backtrace.join("\n")
        @exception_class = exception.class.to_s
        render :template => "general/exception_caught.rhtml", :status => 404
    end
      
    def local_request?
        false
    end

    # Called from test code, is a mimic of User.confirm, for use in following email
    # links when in controller tests (since we don't have full integration tests that
    # can work over multiple controllers)
    def test_code_redirect_by_email_token(token, controller_example_group)
        post_redirect = PostRedirect.find_by_email_token(token)
        if post_redirect.nil?
            raise "bad token in test code email"
        end
        session[:user_id] = post_redirect.user.id
        session[:user_circumstance] = post_redirect.circumstance
        params = controller_example_group.params_from(:get, post_redirect.local_part_uri)
        params.merge(post_redirect.post_params)
        controller_example_group.get params[:action], params
    end

    private

    # Check the user is logged in
    def authenticated?(reason_params)
        unless session[:user_id]
            post_redirect = PostRedirect.new(:uri => request.request_uri, :post_params => params,
                :reason_params => reason_params)
            post_redirect.save!
            redirect_to signin_url(:token => post_redirect.token)
            return false
        end
        return true
    end

    def authenticated_as_user?(user, reason_params) 
        reason_params[:user_name] = user.name
        reason_params[:user_url] = show_user_url(:url_name => user.url_name)
        if session[:user_id]
            if session[:user_id] == user.id
                # They are logged in as the right user
                return true
            else
                # They are already logged in, but as the wrong user
                @reason_params = reason_params
                render :template => 'user/wrong_user'
                return
            end
        end
        # They are not logged in at all
        return authenticated?(reason_params)
    end

    # Return logged in user
    def authenticated_user
        if session[:user_id].nil?
            return nil
        else
            return User.find(session[:user_id])
        end
    end

    # Do a POST redirect. This is a nasty hack - we store the posted values in
    # the session, and when the GET redirect with "?post_redirect=1" happens,
    # load them in.
    def do_post_redirect(uri, params)
        session[:post_redirect_params] = params
        # XXX what is the built in Ruby URI munging function that can do this
        # choice of & vs. ? more elegantly than this dumb if statement?
        if uri.include?("?")
            uri += "&post_redirect=1"
        else
            uri += "?post_redirect=1"
        end
        redirect_to uri
    end

    # If we are in a faked redirect to POST request, then set post params.
    before_filter :check_in_post_redirect
    def check_in_post_redirect
        if params[:post_redirect] and session[:post_redirect_params]
            params.update(session[:post_redirect_params])
        end
    end

    # Default layout shows user in corner, so needs access to it
    before_filter :authentication_check
    def authentication_check
        if session[:user_id]
            @user = authenticated_user
        end
    end

    # For administration interface, return display name of authenticated user
    def admin_http_auth_user
        if not request.env["REMOTE_USER"]
            return "*unknown*";
        else
            return request.env["REMOTE_USER"]
        end
    end
    def assign_http_auth_user
        @http_auth_user = admin_http_auth_user
    end

    # Convert URL name for sort by order, to Xapian query 
    def order_to_sort_by(sortby)
        if sortby.nil?
            return [nil, true]
        elsif sortby == 'newest'
            return ['created_at', false]
        elsif sortby == 'described'
            return ['rss_at', false] # use this for RSS
        else
            raise "Unknown sort order " + @sortby
        end
    end

    # Function for search
    def perform_search(query, sortby, collapse, per_page = 25, this_page = nil, html_highlight = true) 
        @query = query
        @sortby = sortby

        # Work out sorting method
        order_pair = order_to_sort_by(@sortby)
        order = order_pair[0]
        ascending = order_pair[1]

        # Peform the search
        @per_page = per_page
        if this_page.nil?
            @page = (params[:page] || "1").to_i
        else
            @page = this_page
        end
        xapian_object = InfoRequest.full_search(@query, order, ascending, collapse, @per_page, @page) 
        @search_results = xapian_object.results
        @search_hits = xapian_object.matches_estimated
        @search_spelling = xapian_object.spelling_correction

        # Calculate simple word highlighting view code for users and public bodies
        query_nopunc = @query.gsub(/[^a-z0-9]/i, " ")
        query_nopunc = query_nopunc.gsub(/\s+/, " ")
        @highlight_words = query_nopunc.split(" ")
    end

    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper

end



