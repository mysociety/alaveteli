# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.6 2007-09-12 15:27:15 francis Exp $


class ApplicationController < ActionController::Base
    # Standard hearders, footers and navigation for whole site
    layout "default"

    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_foi_session_id'

    # Login form
    def signin
        if request.post?
            user = User.authenticate(params[:email], params[:password])
            if user
                session[:user] = user.id
                redirect_to :action => session[:intended_action], :controller => session[:intended_controller]
            else
                flash[:error] = "Email or password not correct"
            end
        end
        render :template => 'user_accounts/signin'
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
            redirect_to :action => "signin"
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
