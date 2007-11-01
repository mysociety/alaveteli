# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.8 2007-11-01 14:45:56 francis Exp $

class UserController < ApplicationController
    # XXX See controllers/application.rb simplify_url_part for reverse of expression in SQL below
    def show
        @display_users = User.find(:all, :conditions => [ "regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?", params[:simple_name] ], :order => "created_at desc")
    end

    # Login form
    def signin
        # The explict signin link uses this to store where it is to go back to
        if params[:r]
            post_redirect = PostRedirect.new(:uri => params[:r], :post_params => {})
            post_redirect.save!
            params[:token] = post_redirect.token
        end

        if not params[:user] 
            # First time page is shown
            render :template => 'user_accounts/signin' 
            return
        else
            @user = User.authenticate(params[:user][:email], params[:user][:password])
            if @user
                # Successful login
                session[:user] = @user.id
                post_redirect = PostRedirect.find_by_token(params[:token])
                do_post_redirect post_redirect.uri, post_redirect.post_params
                return
            else
                if User.find(:first, :conditions => [ "email = ?", params[:user][:email] ])
                    # Failed to authenticate
                    flash[:error] = "Password not correct, please try again"
                    @user = User.new(params[:user])
                    render :template => 'user_accounts/signin' 
                    return
                else 
                    # Create a new account
                    params[:first_time] = true
                    self.signup
                    return
                end
            end
        end
    end

    # Create new account form
    def signup
        # Make the user and try to save it
        @user = User.new(params[:user])
        if not @user.save
            # First time get to form (e.g. from signin) , don't show errors
            @first_time = params[:first_time]
            @user.errors.clear if @first_time
            # Show the form
            render :template => 'user_accounts/signup'
        else
            # New user made, redirect back to where we were
            session[:user] = @user.id
            post_redirect = PostRedirect.find_by_token(params[:token])
            do_post_redirect post_redirect.uri, post_redirect.post_params
            return
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
