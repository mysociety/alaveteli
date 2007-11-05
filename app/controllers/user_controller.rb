# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.11 2007-11-05 16:46:10 francis Exp $

class UserController < ApplicationController
    # XXX See controllers/application.rb simplify_url_part for reverse of expression in SQL below
    def show
        @display_users = User.find(:all, :conditions => [ "regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?", params[:simple_name] ], :order => "created_at desc")
    end

    # Login form
    def signin
        # The explict signin link uses this to store where it is to go back to
        if params[:r]
            @post_redirect = PostRedirect.new(:uri => params[:r], :post_params => {})
            @post_redirect.save!
            params[:token] = @post_redirect.token
        else
            @post_redirect = PostRedirect.find_by_token(params[:token])
        end

        if not params[:user] 
            # First time page is shown
            render :action => 'signin' 
            return
        else
            @user = User.authenticate(params[:user][:email], params[:user][:password])
            if @user
                # Successful login
                if @user.email_confirmed
                    session[:user] = @user.id
                    do_post_redirect @post_redirect.uri, @post_redirect.post_params
                else
                    send_confirmation_mail
                end
                return
            else
                if User.find(:first, :conditions => [ "email ilike ?", params[:user][:email] ]) # using like for case insensitive
                    # Failed to authenticate
                    flash[:error] = "Password not correct, please try again"
                    @user = User.new(params[:user])
                    render :action => 'signin' 
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
        if not @user.valid?
            # First time get to form (e.g. from signin) , don't show errors
            @first_time = params[:first_time]
            @user.errors.clear if @first_time
            # Show the form
            render :action => 'signup'
        else
            # Unconfirmed user
            @user.email_confirmed = false
            @user.save

            send_confirmation_mail
            return
        end
    end

    # Followed link in user account confirmation email
    def confirm
        post_redirect = PostRedirect.find_by_email_token(params[:email_token])

        # XXX add message like this if post_redirect not found
        #        err(sprintf(_("Please check the URL (i.e. the long code of
        #        letters and numbers) is copied correctly from your email.  If
        #        you can't click on it in the email, you'll have to select and
        #        copy it from the email.  Then paste it into your browser, into
        #        the place you would type the address of any other webpage.
        #        Technical details: The token '%s' wasn't found."), $q_t));
        #

        @user = post_redirect.user
        @user.email_confirmed = true
        @user.save

        session[:user] = @user.id

        do_post_redirect post_redirect.uri, post_redirect.post_params
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

    # Ask for email confirmation
    def send_confirmation_mail
        raise "user #{@user.id} already confirmed" if @user.email_confirmed

        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = @user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.deliver_confirm_login(@user, post_redirect.reason_params, url)
        render :action => 'confirm'
    end

end
