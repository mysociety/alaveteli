# -*- encoding : utf-8 -*-
# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'set'

class UserController < ApplicationController
    layout :select_layout

    # Show page about a user
    def show
        long_cache
        if MySociety::Format.simplify_url_part(params[:url_name], 'user') != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 'user'), :status => :moved_permanently
            return
        end
        if params[:view].nil?
            @show_requests = true
            @show_profile = true
            @show_batches = false
        elsif params[:view] == 'profile'
            @show_profile = true
            @show_requests = false
            @show_batches = false
        elsif params[:view] == 'requests'
            @show_profile = false
            @show_requests = true
            @show_batches = true
        end

        @display_user = User.find(:first, :conditions => [ "url_name = ? and email_confirmed = ?", params[:url_name], true ])
        if not @display_user
            raise ActiveRecord::RecordNotFound.new("user not found, url_name=" + params[:url_name])
        end
        @same_name_users = User.find(:all, :conditions => [ "name ilike ? and email_confirmed = ? and id <> ?", @display_user.name, true, @display_user.id ], :order => "created_at")

        @is_you = !@user.nil? && @user.id == @display_user.id

        # Use search query for this so can collapse and paginate easily
        # TODO: really should just use SQL query here rather than Xapian.
        if @show_requests
            begin

                request_states = @display_user.info_requests.pluck(:described_state).uniq

                option_item = Struct.new(:value, :text)
                @request_states = request_states.map do |state|
                   option_item.new(state, InfoRequest.get_status_description(state))
                end

                requests_query = 'requested_by:' + @display_user.url_name
                comments_query = 'commented_by:' + @display_user.url_name
                if !params[:user_query].nil?
                    requests_query += " " + params[:user_query]
                    comments_query += " " + params[:user_query]
                    @match_phrase = _("{{search_results}} matching '{{query}}'", :search_results => "", :query => params[:user_query])

                    unless params[:request_latest_status].blank?
                        requests_query << ' latest_status:' << params[:request_latest_status]
                        comments_query << ' latest_status:' << params[:request_latest_status]
                        @match_phrase << _(" filtered by status: '{{status}}'", :status => params[:request_latest_status])
                    end
                end

                @xapian_requests = perform_search([InfoRequestEvent], requests_query, 'newest', 'request_collapse')
                @xapian_comments = perform_search([InfoRequestEvent], comments_query, 'newest', nil)

                if (@page > 1)
                    @page_desc = " (page " + @page.to_s + ")"
                else
                    @page_desc = ""
                end
            rescue
                @xapian_requests = nil
                @xapian_comments = nil
            end

            # Track corresponding to this page
            @track_thing = TrackThing.create_track_for_user(@display_user)
            @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

        end
        # All tracks for the user
        if @is_you
            @track_things = TrackThing.find(:all, :conditions => ["tracking_user_id = ? and track_medium = ?", @display_user.id, 'email_daily'], :order => 'created_at desc')
            @track_things_grouped = @track_things.group_by(&:track_type)
        end

        # Requests you need to describe
        if @is_you
            @undescribed_requests = @display_user.get_undescribed_requests
        end

        respond_to do |format|
            format.html { @has_json = true }
            format.json { render :json => @display_user.json_for_api }
        end

    end

    # Show the user's wall
    def wall
        long_cache
        @display_user = User.find(:first, :conditions => [ "url_name = ? and email_confirmed = ?", params[:url_name], true ])
        if not @display_user
            raise ActiveRecord::RecordNotFound.new("user not found, url_name=" + params[:url_name])
        end
        @is_you = !@user.nil? && @user.id == @display_user.id
        feed_results = Set.new
        # Use search query for this so can collapse and paginate easily
        # TODO: really should just use SQL query here rather than Xapian.
        begin
            requests_query = 'requested_by:' + @display_user.url_name
            comments_query = 'commented_by:' + @display_user.url_name
            # TODO: combine these as OR query
            @xapian_requests = perform_search([InfoRequestEvent], requests_query, 'newest', 'request_collapse')
            @xapian_comments = perform_search([InfoRequestEvent], comments_query, 'newest', nil)
        rescue
            @xapian_requests = nil
            @xapian_comments = nil
        end

        feed_results += @xapian_requests.results.map {|x| x[:model]} if !@xapian_requests.nil?
        feed_results += @xapian_comments.results.map {|x| x[:model]} if !@xapian_comments.nil?

        # All tracks for the user
        if @is_you
            @track_things = TrackThing.find(:all, :conditions => ["tracking_user_id = ? and track_medium = ?", @display_user.id, 'email_daily'], :order => 'created_at desc')
            for track_thing in @track_things
                # TODO: factor out of track_mailer.rb
                xapian_object = ActsAsXapian::Search.new([InfoRequestEvent], track_thing.track_query,
                    :sort_by_prefix => 'described_at',
                    :sort_by_ascending => true,
                    :collapse_by_prefix => nil,
                    :limit => 20)
                feed_results += xapian_object.results.map {|x| x[:model]}
            end
        end

        @feed_results = Array(feed_results).sort {|x,y| y.created_at <=> x.created_at}.first(20)

        respond_to do |format|
            format.html { @has_json = true }
            format.json { render :json => @display_user.json_for_api }
        end

    end

    # Login form
    def signin
        work_out_post_redirect
        @request_from_foreign_country = country_from_ip != AlaveteliConfiguration::iso_country_code
        # make sure we have cookies
        if session.instance_variable_get(:@dbman)
            if not session.instance_variable_get(:@dbman).instance_variable_get(:@original)
                # try and set them if we don't
                if !params[:again]
                    redirect_to signin_url(:r => params[:r], :again => 1)
                    return
                end
                render :action => 'no_cookies'
                return
            end
        end
        # remove "cookie setting attempt has happened" parameter if there is one and cookies worked
        if params[:again]
            redirect_to signin_url(:r => params[:r], :again => nil)
            return
        end

        if not params[:user_signin]
            # First time page is shown
            render :action => 'sign'
            return
        else
            if !@post_redirect.nil?
                @user_signin = User.authenticate_from_form(params[:user_signin], @post_redirect.reason_params[:user_name] ? true : false)
            end
            if @post_redirect.nil? || @user_signin.errors.size > 0
                # Failed to authenticate
                render :action => 'sign'
                return
            else
                # Successful login
                if @user_signin.email_confirmed
                    session[:user_id] = @user_signin.id
                    session[:user_circumstance] = nil
                    session[:remember_me] = params[:remember_me] ? true : false

                    if is_modal_dialog
                        render :action => 'signin_successful'
                    else
                        do_post_redirect @post_redirect
                    end
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
        @request_from_foreign_country = country_from_ip != AlaveteliConfiguration::iso_country_code
        # Make the user and try to save it
        @user_signup = User.new(user_params(:user_signup))
        error = false
        if @request_from_foreign_country && !verify_recaptcha
            flash.now[:error] = _("There was an error with the words you entered, please try again.")
            error = true
        end
        if error || !@user_signup.valid?
            # Show the form
            render :action => 'sign'
        else
            user_alreadyexists = User.find_user_by_email(params[:user_signup][:email])
            if user_alreadyexists
                already_registered_mail user_alreadyexists
                return
            else
                # New unconfirmed user
                @user_signup.email_confirmed = false
                @user_signup.save!
                send_confirmation_mail @user_signup
                return
            end
        end
    end

    # Followed link in user account confirmation email.
    # If you change this, change ApplicationController.test_code_redirect_by_email_token also
    def confirm
        post_redirect = PostRedirect.find_by_email_token(params[:email_token])

        if post_redirect.nil?
            render :template => 'user/bad_token'
            return
        end

        if !User.stay_logged_in_on_redirect?(@user) || post_redirect.circumstance == "login_as"
            @user = post_redirect.user
            @user.email_confirmed = true
            @user.save!
        end

        session[:user_id] = @user.id
        session[:user_circumstance] = post_redirect.circumstance

        do_post_redirect post_redirect
    end

    def signout
        clear_session_credentials
        if params[:r]
            redirect_to URI.parse(params[:r]).path
        else
            redirect_to :controller => "general", :action => "frontpage"
        end
    end

    # Change password (TODO: and perhaps later email) - requires email authentication
    def signchangepassword
        if @user and ((not session[:user_circumstance]) or (session[:user_circumstance] != "change_password"))
            # Not logged in via email, so send confirmation
            params[:submitted_signchangepassword_send_confirm] = true
            params[:signchangepassword] = { :email => @user.email }
        end

        if params[:submitted_signchangepassword_send_confirm]
            # They've entered the email, check it is OK and user exists
            if not MySociety::Validate.is_valid_email(params[:signchangepassword][:email])
                flash[:error] = _("That doesn't look like a valid email address. Please check you have typed it correctly.")
                render :action => 'signchangepassword_send_confirm'
                return
            end
            user_signchangepassword = User.find_user_by_email(params[:signchangepassword][:email])
            if user_signchangepassword
                # Send email with login link to go to signchangepassword page
                url = signchangepassword_url
                if params[:pretoken]
                    url += "?pretoken=" + params[:pretoken]
                end
                post_redirect = PostRedirect.new(:uri => url , :post_params => {},
                    :reason_params => {
                        :web => "",
                        :email => _("Then you can change your password on {{site_name}}",:site_name=>site_name),
                        :email_subject => _("Change your password on {{site_name}}",:site_name=>site_name)
                    },
                    :circumstance => "change_password" # special login that lets you change your password
                )
                post_redirect.user = user_signchangepassword
                post_redirect.save!
                url = confirm_url(:email_token => post_redirect.email_token)
                UserMailer.confirm_login(user_signchangepassword, post_redirect.reason_params, url).deliver
            else
                # User not found, but still show confirm page to not leak fact user exists
            end

            render :action => 'signchangepassword_confirm'
        elsif not @user
            # Not logged in, prompt for email
            render :action => 'signchangepassword_send_confirm'
        else
            # Logged in via special email change password link, so can offer form to change password
            raise "internal error" unless (session[:user_circumstance] == "change_password")

            if params[:submitted_signchangepassword_do]
                @user.password = params[:user][:password]
                @user.password_confirmation = params[:user][:password_confirmation]
                if not @user.valid?
                    render :action => 'signchangepassword'
                else
                    @user.save!
                    flash[:notice] = _("Your password has been changed.")
                    if params[:pretoken] and not params[:pretoken].empty?
                        post_redirect = PostRedirect.find_by_token(params[:pretoken])
                        do_post_redirect post_redirect
                    else
                        redirect_to user_url(@user)
                    end
                end
            else
                render :action => 'signchangepassword'
            end
        end
    end

    # Change your email
    def signchangeemail
        if not authenticated?(
                :web => _("To change your email address used on {{site_name}}",:site_name=>site_name),
                :email => _("Then you can change your email address used on {{site_name}}",:site_name=>site_name),
                :email_subject => _("Change your email address used on {{site_name}}",:site_name=>site_name)
            )
            # "authenticated?" has done the redirect to signin page for us
            return
        end

        if !params[:submitted_signchangeemail_do]
            render :action => 'signchangeemail'
            return
        end

        # validate taking into account the user_circumstance
        validator_params = params[:signchangeemail].clone
        validator_params[:user_circumstance] = session[:user_circumstance]
        @signchangeemail = ChangeEmailValidator.new(validator_params)
        @signchangeemail.logged_in_user = @user

        if !@signchangeemail.valid?
            render :action => 'signchangeemail'
            return
        end

        # if new email already in use, send email there saying what happened
        user_alreadyexists = User.find_user_by_email(@signchangeemail.new_email)
        if user_alreadyexists
            UserMailer.changeemail_already_used(@user.email, @signchangeemail.new_email).deliver
            # it is important this screen looks the same as the one below, so
            # you can't change to someone's email in order to tell if they are
            # registered with that email on the site
            render :action => 'signchangeemail_confirm'
            return
        end

        # if not already, send a confirmation link to the new email address which logs
        # them into the old email's user account, but with special user_circumstance
        if (not session[:user_circumstance]) or (session[:user_circumstance] != "change_email")
            # don't store the password in the db
            params[:signchangeemail].delete(:password)
            post_redirect = PostRedirect.new(:uri => signchangeemail_url(),
                                             :post_params => params,
                                             :circumstance => "change_email" # special login that lets you change your email
            )
            post_redirect.user = @user
            post_redirect.save!

            url = confirm_url(:email_token => post_redirect.email_token)
            UserMailer.changeemail_confirm(@user, @signchangeemail.new_email, url).deliver
            # it is important this screen looks the same as the one above, so
            # you can't change to someone's email in order to tell if they are
            # registered with that email on the site
            render :action => 'signchangeemail_confirm'
            return
        end

        # circumstance is 'change_email', so can actually change the email
        @user.email = @signchangeemail.new_email
        @user.save!

        # Now clear the circumstance
        session[:user_circumstance] = nil
        flash[:notice] = _("You have now changed your email address used on {{site_name}}",:site_name=>site_name)
        redirect_to user_url(@user)
    end

    # Send a message to another user
    def contact
        @recipient_user = User.find(params[:id])

        # Banned from messaging users?
        if !authenticated_user.nil? && !authenticated_user.can_contact_other_users?
            @details = authenticated_user.can_fail_html
            render :template => 'user/banned'
            return
        end

        # You *must* be logged into send a message to another user. (This is
        # partly to avoid spam, and partly to have some equanimity of openess
        # between the two users)
        if not authenticated?(
                :web => _("To send a message to ") + CGI.escapeHTML(@recipient_user.name),
                :email => _("Then you can send a message to ") + @recipient_user.name + ".",
                :email_subject => _("Send a message to ") + @recipient_user.name
            )
            # "authenticated?" has done the redirect to signin page for us
            return
        end

        if params[:submitted_contact_form]
            params[:contact][:name] = @user.name
            params[:contact][:email] = @user.email
            @contact = ContactValidator.new(params[:contact])
            if @contact.valid?
                ContactMailer.user_message(
                    @user,
                    @recipient_user,
                    user_url(@user),
                    params[:contact][:subject],
                    params[:contact][:message]
                ).deliver
                flash[:notice] = _("Your message to {{recipient_user_name}} has been sent!",:recipient_user_name=>CGI.escapeHTML(@recipient_user.name))
                redirect_to user_url(@recipient_user)
                return
            end
        else
            @contact = ContactValidator.new(
                { :message => "" + @recipient_user.name + _(",\n\n\n\nYours,\n\n{{user_name}}",:user_name=>@user.name) }
            )
        end

    end

    # River of News: What's happening with your tracked things
    def river
        @results = @user.nil? ? [] : @user.track_things.collect { |thing|
          perform_search([InfoRequestEvent], thing.track_query, thing.params[:feed_sortby], nil).results
        }.flatten.sort { |a,b| b[:model].created_at <=> a[:model].created_at }.first(20)
    end

    def set_profile_photo
        # check they are logged in (the upload photo option is anyway only available when logged in)
        if authenticated_user.nil?
            flash[:error] = _("You need to be logged in to change your profile photo.")
            redirect_to frontpage_url
            return
        end
        if !params[:submitted_draft_profile_photo].nil?
            if @user.banned?
              flash[:error]= _('Banned users cannot edit their profile')
              redirect_to set_profile_photo_path
              return
            end

            # check for uploaded image
            file_name = nil
            file_content = nil
            if !params[:file].nil?
                file_name = params[:file].original_filename
                file_content = params[:file].read
            end

            # validate it
            @draft_profile_photo = ProfilePhoto.new(:data => file_content, :draft => true)
            if !@draft_profile_photo.valid?
                # error page (uses @profile_photo's error fields in view to show errors)
                render :template => 'user/set_draft_profile_photo'
                return
            end
            @draft_profile_photo.save

            if params[:automatically_crop]
                # no javascript, crop automatically
                @profile_photo = ProfilePhoto.new(:data => @draft_profile_photo.data, :draft => false)
                @user.set_profile_photo(@profile_photo)
                @draft_profile_photo.destroy
                flash[:notice] = _("Thank you for updating your profile photo")
                redirect_to user_url(@user)
                return
            end

            render :template => 'user/set_crop_profile_photo'
            return
        elsif !params[:submitted_crop_profile_photo].nil?
            # crop the draft photo according to jquery parameters and set it as the users photo
            draft_profile_photo = ProfilePhoto.find(params[:draft_profile_photo_id])
            @profile_photo = ProfilePhoto.new(:data => draft_profile_photo.data, :draft => false,
                :x => params[:x], :y => params[:y], :w => params[:w], :h => params[:h])
            @user.set_profile_photo(@profile_photo)
            draft_profile_photo.destroy

            if !@user.get_about_me_for_html_display.empty?
                flash[:notice] = _("Thank you for updating your profile photo")
                redirect_to user_url(@user)
            else
                flash[:notice] = _("<p>Thanks for updating your profile photo.</p>
                <p><strong>Next...</strong> You can put some text about you and your research on your profile.</p>")
                redirect_to set_profile_about_me_url()
            end
        else
            render :template => 'user/set_draft_profile_photo'
        end
    end

    def clear_profile_photo
        if !request.post?
            raise "Can only clear profile photo from POST request"
        end

        # check they are logged in (the upload photo option is anyway only available when logged in)
        if authenticated_user.nil?
            flash[:error] = _("You need to be logged in to clear your profile photo.")
            redirect_to frontpage_url
            return
        end

        if @user.profile_photo
            @user.profile_photo.destroy
        end

        flash[:notice] = _("You've now cleared your profile photo")
        redirect_to user_url(@user)
    end

    # before they've cropped it
    def get_draft_profile_photo
        profile_photo = ProfilePhoto.find(params[:id])
        response.content_type = "image/png"
        render :text => profile_photo.data
    end

    # actual profile photo of a user
    def get_profile_photo
        long_cache
        @display_user = User.find(:first, :conditions => [ "url_name = ? and email_confirmed = ?", params[:url_name], true ])
        if !@display_user
            raise ActiveRecord::RecordNotFound.new("user not found, url_name=" + params[:url_name])
        end
        if !@display_user.profile_photo
            raise ActiveRecord::RecordNotFound.new("user has no profile photo, url_name=" + params[:url_name])

        end

        response.content_type = "image/png"
        render :text => @display_user.profile_photo.data
    end

    # Change about me text on your profile page
    def set_profile_about_me
        if authenticated_user.nil?
            flash[:error] = _("You need to be logged in to change the text about you on your profile.")
            redirect_to frontpage_url
            return
        end

        if !params[:submitted_about_me]
            params[:about_me] = {}
            params[:about_me][:about_me] = @user.about_me
            @about_me = AboutMeValidator.new(params[:about_me])
            render :action => 'set_profile_about_me'
            return
        end

        if @user.banned?
          flash[:error] = _('Banned users cannot edit their profile')
          redirect_to set_profile_about_me_path
          return
        end

        @about_me = AboutMeValidator.new(params[:about_me])
        if !@about_me.valid?
            render :action => 'set_profile_about_me'
            return
        end

        @user.about_me = @about_me.about_me
        @user.save!
        if @user.profile_photo
            flash[:notice] = _("You have now changed the text about you on your profile.")
            redirect_to user_url(@user)
        else
            flash[:notice] = _("<p>Thanks for changing the text about you on your profile.</p>
            <p><strong>Next...</strong> You can upload a profile photograph too.</p>")
            redirect_to set_profile_photo_url()
        end
    end

    # Change about me text on your profile page
    def set_receive_email_alerts
        if authenticated_user.nil?
            flash[:error] = _("You need to be logged in to edit your profile.")
            redirect_to frontpage_url
            return
        end
        @user.receive_email_alerts = params[:receive_email_alerts]
        @user.save!
        redirect_to URI.parse(params[:came_from]).path
    end

    private

    def user_params(key = :user)
        params[key].slice(:name, :email, :password, :password_confirmation)
    end

    def is_modal_dialog
        (params[:modal].to_i != 0)
    end

    # when logging in through a modal iframe, don't display chrome around the content
    def select_layout
        is_modal_dialog ? 'no_chrome' : 'default'
    end

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
                    :email => _("Then you can sign in to {{site_name}}",:site_name=>site_name),
                    :email_subject => _("Confirm your account on {{site_name}}",:site_name=>site_name)
                })
            @post_redirect.save!
            params[:token] = @post_redirect.token
        elsif params[:token]
            # Otherwise we have a token (which represents a saved POST request)
            @post_redirect = PostRedirect.find_by_token(params[:token])
        end
    end

    # Ask for email confirmation
    def send_confirmation_mail(user)
        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.confirm_login(user, post_redirect.reason_params, url).deliver
        render :action => 'confirm'
    end

    # If they register again
    def already_registered_mail(user)
        post_redirect = PostRedirect.find_by_token(params[:token])
        post_redirect.user = user
        post_redirect.save!

        url = confirm_url(:email_token => post_redirect.email_token)
        UserMailer.already_registered(user, post_redirect.reason_params, url).deliver
        render :action => 'confirm' # must be same as for send_confirmation_mail above to avoid leak of presence of email in db
    end

end

