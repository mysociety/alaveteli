# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.7 2007-10-31 17:25:29 francis Exp $

class UserController < ApplicationController
    # XXX See controllers/application.rb simplify_url_part for reverse of expression in SQL below
    def show
        @display_users = User.find(:all, :conditions => [ "regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?", params[:simple_name] ], :order => "created_at desc")
    end

    # Login form
    def signin
        # The explict signin link uses this to store where it is to go back to
        if params[:r]
            session[:intended_uri] = params[:r]
            session[:intended_params] = nil
        end

        if not params[:user] 
            # First time page is shown
            render :template => 'user_accounts/signin' and return
        else
            @user = User.authenticate(params[:user][:email], params[:user][:password])
            if @user
                # Successful login
                session[:user] = @user.id
                post_redirect session[:intended_uri], session[:intended_params] and return
            else
                if User.find(:first, :conditions => [ "email = ?", params[:user][:email] ])
                    # Failed to authenticate
                    flash[:error] = "Password not correct, please try again"
                    @user = User.new(params[:user])
                    render :template => 'user_accounts/signin' and return
                else 
                    # "I am new to FOIFA"
                    session[:email] = params[:user][:email]
                    session[:password] = params[:user][:password]
                    session[:first_time] = true
                    redirect_to :action => 'signup' and return
                end
            end
        end
    end

    # Create new account form
    def signup
        # Default to value saved from signin form
        params[:user] ||= { :email => session[:email] }
        params[:user] ||= { :password => session[:password] }

        # Make the user and try to save it
        @user = User.new(params[:user])
        if not @user.save
            # First time get to form (e.g. from signin) , don't show errors
            if session[:first_time]
                @first_time = true
                @user.errors.clear
                session[:first_time] = false
            end
            # Show the form
            render :template => 'user_accounts/signup'
        else
            # New user made, redirect back to where we were
            session[:user] = @user.id
            post_redirect session[:intended_uri], session[:intended_params] and return
        end
    end

    # Logout form
    def signout
        session[:user] = nil
        if params[:r]
            redirect_to params[:r]
        else
            redirect_to :action => "index"
        end
    end


    private

end
