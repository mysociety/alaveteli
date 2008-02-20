# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.26 2008-02-20 12:51:29 francis Exp $

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
                    session[:user_authtype] = :password
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
        session[:user_authtype] = :email

        do_post_redirect post_redirect.uri, post_redirect.post_params
    end

    # Logout form
    def signout
        session[:user_id] = nil
        session[:user_authtype] = nil
        if params[:r]
            redirect_to params[:r]
        else
            redirect_to :controller => "request", :action => "frontpage"
        end
    end

    # Change password and/or email - requires email authentication
    def signchange
        if @user and ((not session[:user_authtype]) or (session[:user_authtype] != :email))
            # Not logged in via email, so send confirmation
            params[:submitted_signchange_email] = true
            params[:signchange] = { :email => @user.email }
        end

        if params[:submitted_signchange_email]
            # They've entered the email, check it is OK and user exists
            if not MySociety::Validate.is_valid_email(params[:signchange][:email])
                flash[:error] = "That doesn't look like a valid email address. Please check you have typed it correctly."
                render :action => 'signchange_email'
                return
            end
            user_signchange = User.find_user_by_email(params[:signchange][:email])
            if not user_signchange
                flash[:error] = "There is no user with that email, please check you have typed it correctly."
                render :action => 'signchange_email'
                return
            end

            # Send email with login link to go to signchange page
            url = signchange_url
            if params[:pretoken]
                url += "?pretoken=" + params[:pretoken]
            end
            post_redirect = PostRedirect.new(:uri => url , :post_params => {},
                :reason_params => {
                    :web => "",
                    :email => "Then your can change your password on foi.mysociety.org",
                    :email_subject => "Change your password on foi.mysociety.org"
                })
            post_redirect.user = user_signchange
            post_redirect.save!
            url = confirm_url(:email_token => post_redirect.email_token)
            UserMailer.deliver_confirm_login(user_signchange, post_redirect.reason_params, url)
            render :action => 'confirm'
        elsif not @user
            # Not logged in, prompt for email
            render :action => 'signchange_email'
        else
            # Logged in via email link, so can offer form to change email/password
            raise "internal error" unless (session[:user_authtype] == :email)

            if params[:submitted_signchange_password]
                @user.password = params[:user][:password]
                @user.password_confirmation = params[:user][:password_confirmation]
                if not @user.valid?
                    render :action => 'signchange'
                else
                    @user.save!
                    flash[:notice] = "Your password has been changed."
                    if params[:pretoken] and not params[:pretoken].empty?
                        post_redirect = PostRedirect.find_by_token(params[:pretoken])
                        do_post_redirect post_redirect.uri, post_redirect.post_params
                    else    
                        redirect_to :controller => "request", :action => "frontpage" # XXX should go back to login and where they were!
                    end
                end
            else
                render :action => 'signchange'
            end
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
                    :email => "Then your can sign in to foi.mysociety.org",
                    :email_subject => "Confirm your account on foi.mysociety.org"
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
        #raise "user #{user.id} already confirmed" if user.email_confirmed

        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.deliver_confirm_login(user, post_redirect.reason_params, url)
        render :action => 'confirm'
    end

end
