# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.24 2008-02-12 11:42:09 francis Exp $

class UserController < ApplicationController
    # XXX See controllers/application.rb simplify_url_part for reverse of expression in SQL below
    def show
        if simplify_url_part(params[:simple_name]) != params[:simple_name]
            redirect_to :simple_name => simplify_url_part(params[:simple_name])
        end

        @display_users = User.find(:all, :conditions => [ "regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?", params[:simple_name] ], :order => "created_at desc")
    end

    # Login form
    def signin
        work_out_post_redirect

        if not params[:user_signin] 
            # First time page is shown
            render :action => 'sign' 
            return
        else
            @user_signin = User.authenticate_from_form(params[:user_signin], @post_redirect.reason_params[:user_name] ? true : false)
            if @user_signin.errors.size > 0
                # Failed to authenticate
                render :action => 'sign' 
                return
            else
                # Successful login
                if @user_signin.email_confirmed
                    session[:user_id] = @user_signin.id
                    do_post_redirect @post_redirect.uri, @post_redirect.post_params
                else
                    send_confirmation_mail @user_signin
                end
                return
            end
        end
    end

    # Create new account form
    def signup
        work_out_post_redirect

        # Make the user and try to save it
        @user_signup = User.new(params[:user_signup])
        if not @user_signup.valid?
            # Show the form
            render :action => 'sign'
        else
            # New unconfirmed user
            @user_signup.email_confirmed = false
            @user_signup.save!

            send_confirmation_mail @user_signup
            return
        end
    end

    # Followed link in user account confirmation email
    def confirm
        post_redirect = PostRedirect.find_by_email_token(params[:email_token])

        if post_redirect.nil?
            render :template => 'user/bad_token.rhtml'
            return
        end

        @user = post_redirect.user
        @user.email_confirmed = true
        @user.save!

        session[:user_id] = @user.id

        do_post_redirect post_redirect.uri, post_redirect.post_params
    end

    # Logout form
    def signout
        session[:user_id] = nil
        if params[:r]
            redirect_to params[:r]
        else
            redirect_to :controller => "request", :action => "frontpage"
        end
    end


    private

    # Decide where we are going to redirect back to after signin/signup, and record that
    def work_out_post_redirect
        # Redirect to front page later if nothing else specified
        if not params[:r] and not params[:token]
            params[:r] = "/"  
        end
        # The explicit "signin" link uses this to specify where to go back to
        if params[:r]
            @post_redirect = PostRedirect.new(:uri => params[:r], :post_params => {},
                :reason_params => {
                    :web => "",
                    :email => "Then your can sign in to GovernmentSpy.",
                    :email_subject => "Confirm your account on GovernmentSpy"
                })
            @post_redirect.save!
            params[:token] = @post_redirect.token
        elsif params[:token]
            # Otherwise we have a token (which represents a saved POST request0
            @post_redirect = PostRedirect.find_by_token(params[:token])
        end
    end

    # Ask for email confirmation
    def send_confirmation_mail(user)
        raise "user #{user.id} already confirmed" if user.email_confirmed

        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.deliver_confirm_login(user, post_redirect.reason_params, url)
        render :action => 'confirm'
    end

end
