# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.2 2007-08-01 16:41:32 francis Exp $


class ApplicationController < ActionController::Base
    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_foi_session_id'

    def check_authentication
        unless session[:user]
            session[:intended_action] = action_name
            session[:intended_controller] = controller_name
            redirect_to :action => "signin"
        end
    end

    def signin
        if request.post?
            user = User.authenticate(params[:email], params[:password])
            if user
                session[:user] = user.id
                redirect_to :action => session[:intended_action], :controller => session[:intended_controller]
            else
                flash[:notice] = "Email or password not correct"
            end

        end
    end

    def signout
        sessions[:user] = nil
        redirect_to frontpage
    end

end
