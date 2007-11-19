# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.24 2007-11-19 12:36:57 francis Exp $


class ApplicationController < ActionController::Base
    # Standard hearders, footers and navigation for whole site
    layout "default"

    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_foi_session_id'

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
        reason_params[:user_url] = show_user_url(:simple_name => simplify_url_part(user.name))
        if session[:user_id]
            if session[:user_id] == user.id
                # They are logged in as the right user
                return true
            else
                # They are already logged in, but as the wrong user
                @reason_params = reason_params
                render 'user/wrong_user'
            end
        end
        # They are not logged in at all
        return authenticated?(reason_params)
    end

    # Return logged in user
    def authenticated_user
        return User.find(session[:user_id])
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

    # URL generating functions are needed by all controllers (for redirects)
    # and views (for links), so include them into all of both.
    include LinkToHelper

end



