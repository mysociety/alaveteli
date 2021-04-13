# -*- encoding : utf-8 -*-
# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'set'
require 'survey'

class UserController < ApplicationController
  include UserSpamCheck

  layout :select_layout
  before_action :normalize_url_name, :only => :show
  before_action :work_out_post_redirect, :only => [ :signup ]
  before_action :set_request_from_foreign_country, :only => [ :signup ]
  before_action :set_in_pro_area, :only => [ :signup ]

  # Normally we wouldn't be verifying the authenticity token on these actions
  # anyway as there shouldn't be a user_id in the session when the before
  # filter run. This skip handles cases where an already logged in user
  # tries to sign in or sign up. There's little CSRF potential here as
  # these actions only sign in or up users with valid credentials. The
  # user_id in the session is not expected, and gives no extra privilege
  skip_before_action :verify_authenticity_token, :only => [:signin, :signup]

  # Show page about a user
  def show
    long_cache
    @display_user = set_display_user
    set_view_instance_variables
    @same_name_users = User.find_similar_named_users(@display_user)
    @is_you = current_user_is_display_user

    set_show_requests if @show_requests

    @private_requests = []

    if @is_you
      private_requests =
        @display_user.
          info_requests.
          visible_to_requester.
          embargoed

      if params[:user_query]
        private_requests = private_requests.
          where("info_requests.title ILIKE :q", q: "%#{ params[:user_query] }%")
      end

      unless params[:request_latest_status].blank?
        private_requests = private_requests.
          where(described_state: params[:request_latest_status])
      end

      @private_requests =
        private_requests.page(params[:page]).per_page(@per_page)

      # All tracks for the user
      @track_things = TrackThing.
        where(:tracking_user_id => @display_user, :track_medium => 'email_daily').
          order('created_at desc')
      @track_things_grouped = @track_things.group_by(&:track_type)
      # Requests you need to describe
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
    @display_user = set_display_user
    @is_you = current_user_is_display_user
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

    feed_results += @xapian_requests.results.map { |x| x[:model] } if @xapian_requests
    feed_results += @xapian_comments.results.map { |x| x[:model] } if @xapian_comments

    # All tracks for the user
    if @is_you
      @track_things = TrackThing.
        where(:tracking_user_id => @display_user.id,
              :track_medium => 'email_daily').
          order('created_at desc')
      @track_things.each do |track_thing|
        # TODO: factor out of track_mailer.rb
        xapian_object = ActsAsXapian::Search.new([InfoRequestEvent], track_thing.track_query,
                                                 :sort_by_prefix => 'described_at',
                                                 :sort_by_ascending => true,
                                                 :collapse_by_prefix => nil,
                                                 :limit => 20)
        feed_results += xapian_object.results.map { |x| x[:model] }
      end
    end

    @feed_results = feed_results.to_a.sort { |x, y| y.created_at <=> x.created_at }.first(20)

    @feed_results = [] if @display_user.closed?

    respond_to do |format|
      format.html { @has_json = true }
      format.json { render :json => @display_user.json_for_api }
    end

  end

  # Create new account form
  def signup
    # Make the user and try to save it
    @user_signup = User.new(user_params(:user_signup))
    error = false
    if @request_from_foreign_country && !verify_recaptcha
      flash.now[:error] = _('There was an error with the reCAPTCHA. ' \
                              'Please try again.')
      error = true
    end
    @user_signup.valid?
    user_alreadyexists = User.find_user_by_email(params[:user_signup][:email])
    if user_alreadyexists
      # attempt to remove the 'already in use message' from the errors hash
      # so it doesn't get accidentally shown to the end user
      @user_signup.errors[:email].delete_if { |message| message == _("This email is already in use") }
    end
    if error || !@user_signup.errors.empty?
      # Show the form
      render :action => 'sign'
    else
      if user_alreadyexists
        already_registered_mail user_alreadyexists
        return
      else
        # New unconfirmed user

        # Rate limit signups
        ip_rate_limiter.record(user_ip)

        if ip_rate_limiter.limit?(user_ip)
          handle_rate_limited_signup(user_ip, @user_signup.email) && return
        end

        # Prevent signups from potential spammers
        if spam_user?(@user_signup)
          handle_spam_user(@user_signup) do
            render action: 'sign'
          end && return
        end

        @user_signup.email_confirmed = false
        @user_signup.save!
        send_confirmation_mail @user_signup
        return
      end
    end
  end

  def ip_rate_limiter
    @ip_rate_limiter ||= AlaveteliRateLimiter::IPRateLimiter.new(:signup)
  end

  # Change your email
  def signchangeemail
    # "authenticated?" has done the redirect to signin page for us
    return unless authenticated?(
        :web => _("To change your email address used on {{site_name}}",:site_name=>site_name),
        :email => _("Then you can change your email address used on {{site_name}}",:site_name=>site_name),
        :email_subject => _("Change your email address used on {{site_name}}",:site_name=>site_name)
      )

    unless params[:submitted_signchangeemail_do]
      render :action => 'signchangeemail'
      return
    end

    # validate taking into account the user_circumstance
    validator_params = params[:signchangeemail].clone
    validator_params[:user_circumstance] = session[:user_circumstance]
    @signchangeemail = ChangeEmailValidator.new(validator_params)
    @signchangeemail.logged_in_user = @user

    unless @signchangeemail.valid?
      render :action => 'signchangeemail'
      return
    end

    # if new email already in use, send email there saying what happened
    user_alreadyexists = User.find_user_by_email(@signchangeemail.new_email)
    if user_alreadyexists
      UserMailer.
        changeemail_already_used(
          @user.email,
          @signchangeemail.new_email
        ).deliver_now
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
      post_redirect = PostRedirect.new(:uri => signchangeemail_url,
                                       :post_params => params,
                                       :circumstance => "change_email" # special login that lets you change your email
                                       )
      post_redirect.user = @user
      post_redirect.save!

      url = confirm_url(:email_token => post_redirect.email_token)
      UserMailer.
        changeemail_confirm(
          @user,
          @signchangeemail.new_email, url
        ).deliver_now
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
    if params[:submitted_draft_profile_photo].present?
      if @user.suspended?
        flash[:error]= _('Suspended users cannot edit their profile')
        redirect_to set_profile_photo_path
        return
      end

      # check for uploaded image
      file_name = nil
      file_content = nil
      unless params[:file].nil?
        file_name = params[:file].original_filename
        file_content = params[:file].read
      end

      # validate it
      @draft_profile_photo = ProfilePhoto.new(:data => file_content, :draft => true)
      unless @draft_profile_photo.valid?
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
    elsif params[:submitted_crop_profile_photo].present?
      # crop the draft photo according to jquery parameters and set it as the users photo
      draft_profile_photo = ProfilePhoto.find(params[:draft_profile_photo_id])
      @profile_photo = ProfilePhoto.new(:data => draft_profile_photo.data, :draft => false,
                                        :x => params[:x], :y => params[:y], :w => params[:w], :h => params[:h])
      @user.set_profile_photo(@profile_photo)
      draft_profile_photo.destroy


      if @user.get_about_me_for_html_display.empty?
        flash[:notice] = { :partial => "user/update_profile_photo.html.erb" }
        redirect_to edit_profile_about_me_url
      else
        flash[:notice] = _("Thank you for updating your profile photo")
        redirect_to user_url(@user)
      end
    else
      render :template => 'user/set_draft_profile_photo'
    end
  end

  def clear_profile_photo

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
    render :body => profile_photo.data,
           :content_type => 'image/png'
  end

  # actual profile photo of a user
  def get_profile_photo
    long_cache
    @display_user = set_display_user
    unless @display_user.profile_photo
      raise ActiveRecord::RecordNotFound.new("user has no profile photo, url_name=" + params[:url_name])
    end

    render :body => @display_user.profile_photo.data,
           :content_type => 'image/png'
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
    redirect_to SafeRedirect.new(params[:came_from]).path
  end

  def survey
  end

  # Reset the state of the survey so it can be answered again.
  # Handy for testing; not allowed in production.
  def survey_reset
    raise "Not allowed in production" if ENV["RAILS_ENV"] == "production"
    raise "Not logged in" if !@user
    @user.survey.allow_new_survey
    return redirect_to survey_url
  end

  private

  def set_request_from_foreign_country
    @request_from_foreign_country =
      country_from_ip != AlaveteliConfiguration.iso_country_code
  end

  def set_in_pro_area
    @in_pro_area = true if @post_redirect && @post_redirect.reason_params[:pro]
  end

  def normalize_url_name
    unless MySociety::Format.simplify_url_part(params[:url_name], 'user') == params[:url_name]
      redirect_to :url_name => MySociety::Format.simplify_url_part(params[:url_name], 'user'), :status => :moved_permanently
    end
  end

  def set_view_instance_variables
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

    if @display_user.closed?
      @show_requests = false
      @show_batches = false
    end
  end

  def user_params(key = :user)
    params.require(key).permit(:name, :email, :password, :password_confirmation)
  end

  def is_modal_dialog
    params[:modal].to_i != 0
  end

  # when logging in through a modal iframe, don't display chrome around the content
  def select_layout
    is_modal_dialog ? 'no_chrome' : 'default'
  end

  # Decide where we are going to redirect back to after signin/signup,
  # and record that
  def work_out_post_redirect
    # Redirect to front page later if nothing else specified
    params[:r] = "/" if params[:r].nil? && params[:token].nil?

    # The explicit "signin" link uses this to specify where to go back to
    if params[:r]
      @post_redirect = generate_post_redirect_for_signup(params[:r])
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
    UserMailer.
      confirm_login(
        user,
        post_redirect.reason_params,
        url
      ).deliver_now
    render :action => 'confirm'
  end

  # If they register again
  def already_registered_mail(user)
    post_redirect = PostRedirect.find_by_token(params[:token])
    post_redirect ||= generate_post_redirect_for_signup(params[:r])
    post_redirect.user = user
    post_redirect.save!

    url = confirm_url(:email_token => post_redirect.email_token)
    UserMailer.
      already_registered(
        user,
        post_redirect.reason_params,
        url
      ).deliver_now
    render :action => 'confirm' # must be same as for send_confirmation_mail above to avoid leak of presence of email in db
  end

  def assign_request_states(display_user)
    option_item = Struct.new(:value, :text)

    display_user.info_requests.pluck(:described_state).uniq.map do |state|
      option_item.new(state, InfoRequest.get_status_description(state))
    end
  end

  def set_display_user
    User.find_by!(url_name: params[:url_name], email_confirmed: true)
  end

  def set_show_requests
    # Use search query for this so can collapse and paginate easily
    # TODO: really should just use SQL query here rather than Xapian.

    @request_states = assign_request_states(@display_user)

    requests_query = 'requested_by:' + @display_user.url_name
    comments_query = 'commented_by:' + @display_user.url_name
    if params[:user_query]
      requests_query += " " + params[:user_query]
      comments_query += " " + params[:user_query]
      @match_phrase = _("{{search_results}} matching '{{query}}'", :search_results => "", :query => params[:user_query])

      unless params[:request_latest_status].blank?
        requests_query << ' latest_status:' << params[:request_latest_status]
        comments_query << ' latest_status:' << params[:request_latest_status]
        @match_phrase << _(" filtered by status: '{{status}}'", :status => params[:request_latest_status])
      end
    end

    begin
      @xapian_requests = perform_search([InfoRequestEvent], requests_query, 'newest', 'request_collapse')
      @xapian_comments = perform_search([InfoRequestEvent], comments_query, 'newest', nil)
    # TODO: make this rescue specific to errors thrown when xapian is not working
    rescue
      @xapian_requests = nil
      @xapian_comments = nil
    end

    @page_desc = (@page > 1) ? " (page " + @page.to_s + ")" : ""

    # Track corresponding to this page
    @track_thing = TrackThing.create_track_for_user(@display_user)
    @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]
  end

  def current_user_is_display_user
    @user.try(:id) == @display_user.id
  end

  # Redirects to front page later if nothing else specified
  def generate_post_redirect_for_signup(redirect_to="/")
    redirect_to = "/" if redirect_to.nil?
    PostRedirect.new(:uri => redirect_to,
                     :post_params => {},
                     :reason_params => {
                       :web => "",
                       :email => _("Then you can sign in to {{site_name}}", :site_name => site_name),
                       :email_subject => _("Confirm your account on {{site_name}}", :site_name => site_name)
                     })
  end

  def block_rate_limited_ips?
    AlaveteliConfiguration.block_rate_limited_ips ||
      AlaveteliConfiguration.enable_anti_spam
  end

  def handle_rate_limited_signup(user_ip, email_address)
    if send_exception_notifications?
      msg = "Rate limited signup from #{ user_ip } email: " \
            " #{ email_address }"
      e = Exception.new(msg)
      ExceptionNotifier.notify_exception(e, :env => request.env)
    end

    if block_rate_limited_ips?
      flash.now[:error] =
        _("Sorry, we're currently unable to sign up new users, " \
          "please try again later")
      error = true
      render :action => 'sign'
      true
    end
  end

  def spam_should_be_blocked?
    AlaveteliConfiguration.block_spam_signups ||
      AlaveteliConfiguration.enable_anti_spam
  end

end
