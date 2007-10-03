# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.8 2007-10-03 17:13:50 francis Exp $


class ApplicationController < ActionController::Base
    # Standard hearders, footers and navigation for whole site
    layout "default"

    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_foi_session_id'

    # Login form
    def signin
        if not params[:user] 
            # First time page is shown
            render :template => 'user_accounts/signin'
        elsif params[:returning] == "0"
            # "I am new to FOIFA"
            session[:email] = params[:user][:email]
            redirect_to :action => 'signup'
        elsif params[:returning] == "1"
            # "I am returning to FOIFA and my password is"
            @user = User.authenticate(params[:user][:email], params[:user][:password])
            if @user
                # Successful login
                session[:user] = @user.id
                redirect_to :action => session[:intended_action], :controller => session[:intended_controller], :post_redirect => 1
            else
                # Failed to authenticate
                flash[:error] = "Email or password not correct, please try again"
            end
            @user = User.new(params[:user])
            render :template => 'user_accounts/signin'
        else
            # Form submitted, but didn't specify whether had already used FOIFA or not
            flash[:error] = "Please say whether you already have a FOIFA account or not"
            @user = User.new(params[:user])
            render :template => 'user_accounts/signin'
        end
    end

    # Create new account form
    def signup
        # Default to value saved from signin form
        params[:user] ||= { :email => session[:email] }

        # Make the user and try to save it
        @user = User.new(params[:user])
        if not @user.save
            render :template => 'user_accounts/signup'
        else
            # New user made, redirect back to where we were
            session[:user] = @user.id
            redirect_to :action => session[:intended_action], :controller => session[:intended_controller], :post_redirect => 1
        end
    end

    # Logout form
    def signout
        sessions[:user] = nil
        redirect_to frontpage
    end

    private

    # Check the user is logged in
    def check_authentication
        unless session[:user]
            session[:intended_action] = action_name
            session[:intended_controller] = controller_name
            session[:intended_params] = params
            redirect_to :action => "signin"
            return false
        end
        return true
    end

    # For redirects to POST requests
    before_filter :post_redirect
    def post_redirect
        #raise session[:intended_params].to_yaml
        if params[:post_redirect]
# XXX this is the bit where I want to set params for the controller from the session
#            CGI::QueryExtension.params = session[:intended_params]
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

end
