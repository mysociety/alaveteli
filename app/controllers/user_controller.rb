# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'set'

class UserController < ApplicationController
  include UserSpamCheck

  read_only :signups, only: [:signup]

  skip_before_action :html_response, only: [:show, :wall]

  layout :select_layout

  before_action :normalize_url_name, only: :show
  before_action :work_out_post_redirect, only: [ :signup ]
  before_action :set_request_from_foreign_country, only: [ :signup ]
  before_action :set_in_pro_area, only: [ :signup ]
  before_action :set_display_user, only: [ :show, :wall ]
  before_action :set_no_crawl_headers, only: [ :wall ]
  before_action :set_no_crawl_headers_if_suspended, only: [ :show ]

  # Normally we wouldn't be verifying the authenticity token on these actions
  # anyway as there shouldn't be a user_id in the session when the before
  # filter run. This skip handles cases where an already logged in user
  # tries to sign in or sign up. There's little CSRF potential here as
  # these actions only sign in or up users with valid credentials. The
  # user_id in the session is not expected, and gives no extra privilege
  skip_before_action :verify_authenticity_token, only: [:signup]

  # Show page about a user
  def show
    long_cache
    set_view_instance_variables
    @same_name_users = User.find_similar_named_users(@display_user)
    @is_you = current_user_is_display_user

    set_show_requests if @show_requests

    @private_requests = []
    @has_recent_requests = false

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
        where(tracking_user_id: @display_user, track_medium: 'email_daily').
          order(created_at: :desc)
      @track_things_grouped = @track_things.group_by(&:track_type)
      # Requests you need to describe
      @undescribed_requests = @display_user.get_undescribed_requests

      # very recent requests might not show up immediately on a user's page
      # leading to unneeded actions like resends, or support emails. Warn them.
      @has_recent_requests = 
        @display_user.
          info_requests.
          visible_to_requester.
          where(created_at: ..1.hour.ago).
          exists?
    end

    respond_to do |format|
      format.html { @has_json = true }
      format.json { render json: @display_user.json_for_api }
    end
  end

  # Show the user's wall
  def wall
    long_cache
    @is_you = current_user_is_display_user
    feed_results = Set.new
    # Use search query for this so can collapse and paginate easily
    # TODO: really should just use SQL query here rather than Xapian.
    begin
      requests_query = 'requested_by:' + @display_user.url_name
      comments_query = 'commented_by:' + @display_user.url_name
      # TODO: combine these as OR query
      @request_results = perform_search(
        [InfoRequestEvent], requests_query,
        'newest', 'request_collapse'
      )
      @comment_results = perform_search(
        [InfoRequestEvent], comments_query, 'newest', nil
      )

    rescue
      @request_results = nil
      @comment_results = nil
    end

    if @request_results
      feed_results += @request_results.results.map { |x| x[:model] }
    end
    if @comment_results
      feed_results += @comment_results.results.map { |x| x[:model] }
    end

    # All tracks for the user
    if @is_you
      @track_things = TrackThing.
        where(tracking_user_id: @display_user.id,
              track_medium: 'email_daily').
          order(created_at: :desc)
      @track_things.each do |track_thing|
        results = track_thing.matches(sort_by: 'described_at',
                                      limit: 20)
        feed_results += results.events
      end
    end

    @feed_results = feed_results.to_a.sort { |x, y| y.created_at <=> x.created_at }.first(20)

    @feed_results = [] if @display_user.closed?

    respond_to do |format|
      format.html { @has_json = true }
      format.json { render json: @display_user.json_for_api }
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
      @user_signup.errors.delete(:email, :taken)
    end
    if error || !@user_signup.errors.empty?
      # Show the form
      render action: 'sign'
    else
      if user_alreadyexists
        already_registered_mail user_alreadyexists
      else
        # New unconfirmed user

      # Block signups from suspicious countries
      # TODO: Add specs (see RequestController#create)
      # TODO: Extract to UserSpamScorer?
      if blocked_ip?
        handle_blocked_ip(@user_signup) && return
      end

      # Rate limit signups
      ip_rate_limiter.record(user_ip)

      if ip_rate_limiter.limit?(user_ip)
        handle_rate_limited_signup(user_ip, @user_signup.email) && return
      end

      # Prevent signups from potential spammers
      if spam_user?(@user_signup)
        handle_spam_user(@user_signup, 'signup') do
          render action: 'sign'
        end && return
      end

        @user_signup.email_confirmed = false
        @user_signup.save!
        send_confirmation_mail @user_signup
      end
      nil
    end

  rescue ActionController::ParameterMissing
    flash[:error] = _('Invalid form submission')
    render action: :sign
  end

  # A webserver level redirect can be used to redirect from the signup action to
  # prevent spam signups from Tor.
  def tor
    long_cache

    msg = _('Signups from Tor have been blocked due to extensive misuse. ' \
            'Please contact us if this is a problem for you.')

    render plain: msg, status: :forbidden
  end

  def ip_rate_limiter
    @ip_rate_limiter ||= AlaveteliRateLimiter::IPRateLimiter.new(:signup)
  end

  # Change your email
  def signchangeemail
    # "authenticated?" has done the redirect to signin page for us
    return unless authenticated? || ask_to_login(
      web: _('To change your email address used on {{site_name}}',
             site_name: site_name),
      email: _('Then you can change your email address used on {{site_name}}',
               site_name: site_name),
      email_subject: _('Change your email address used on {{site_name}}',
                       site_name: site_name)
    )

    unless params[:submitted_signchangeemail_do]
      render action: 'signchangeemail'
      return
    end

    # validate taking into account the user_circumstance
    validator_params = params[:signchangeemail].clone
    validator_params[:user_circumstance] = session[:user_circumstance]
    validator_params[:post_redirect_token] = session[:post_redirect_token]
    @signchangeemail = ChangeEmailValidator.new(validator_params)
    @signchangeemail.logged_in_user = @user

    unless @signchangeemail.valid?
      render action: 'signchangeemail'
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
      render action: 'signchangeemail_confirm'
      return
    end

    # if not already, send a confirmation link to the new email address which logs
    # them into the old email's user account, but with special user_circumstance
    if !session[:user_circumstance] || (session[:user_circumstance] != "change_email")
      # don't store the password in the db
      params[:signchangeemail].delete(:password)

      post_redirect = PostRedirect.create!(
        uri: signchangeemail_url,
        post_params: params,
        user: @user,
        circumstance: 'change_email'
      )

      url = confirm_url(email_token: post_redirect.email_token)
      UserMailer.
        changeemail_confirm(
          @user,
          @signchangeemail.new_email, url
        ).deliver_now
      # it is important this screen looks the same as the one above, so
      # you can't change to someone's email in order to tell if they are
      # registered with that email on the site
      render action: 'signchangeemail_confirm'
      return
    end

    # circumstance is 'change_email', so can actually change the email
    old_email = @user.email
    @user.email = @signchangeemail.new_email

    if spam_user?(@user)
      handle_spam_user(@user, 'email change') do
        render action: 'signchangeemail'
      end && return
    end

    @user.save!

    # Record the email change in history
    @user.email_histories.record_change(old_email, @signchangeemail.new_email)

    sign_in(@user)

    # Now clear the circumstance
    session[:user_circumstance] = nil
    flash[:notice] = _("You have now changed your email address used on {{site_name}}",site_name: site_name)
    redirect_to user_url(@user)
  end

  # River of News: What's happening with your tracked things
  def river
    @results = if @user.nil?
      []
    else
      @user.
        track_things.
        flat_map { |thing| perform_track_search(thing).events }.
        sort { |a, b| b.created_at <=> a.created_at }.
        first(20)
    end
  end

  # Change about me text on your profile page
  def set_receive_email_alerts
    unless authenticated?
      redirect_to frontpage_url,
                  error: _("You need to be logged in to edit your profile.")
      return
    end
    @user.receive_email_alerts = params[:receive_email_alerts]
    @user.save!
    redirect_to SafeRedirect.new(params[:came_from]).path
  end

  private

  def block_restricted_country_ips?
    AlaveteliConfiguration.block_restricted_country_ips ||
      AlaveteliConfiguration.enable_anti_spam
  end

  def handle_blocked_ip(user)
    if send_exception_notifications?
      msg = "Possible spam signup (ip_in_blocklist) from " \
            "#{user.email}: #{user_ip} (#{country_from_ip})"
      ExceptionNotifier.notify_exception(Exception.new(msg), env: request.env)
    end

    if block_restricted_country_ips?
      flash.now[:error] = _("Sorry, we're currently unable to create your " \
                            "account. Please try again later.")
      render action: 'sign'
      true
    end
  end

  def set_request_from_foreign_country
    @request_from_foreign_country =
      country_from_ip != AlaveteliConfiguration.iso_country_code
  end

  def set_in_pro_area
    @in_pro_area = true if @post_redirect && @post_redirect.reason_params[:pro]
  end

  def set_no_crawl_headers_if_suspended
    set_no_crawl_headers if @display_user&.suspended?
  end

  def normalize_url_name
    unless MySociety::Format.simplify_url_part(params[:url_name], 'user') == params[:url_name]
      redirect_to url_name: MySociety::Format.simplify_url_part(params[:url_name], 'user'), status: :moved_permanently
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

  # when logging in through a modal iframe, don't display chrome around the content
  def select_layout
    modal_dialog? ? 'no_chrome' : 'default'
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
    post_redirect = generate_confirmation_post_redirect(user)

    url = confirm_url(email_token: post_redirect.email_token)
    UserMailer.
      confirm_login(
        user,
        post_redirect.reason_params,
        url
      ).deliver_now
    render action: 'confirm'
  end

  # If they register again
  def already_registered_mail(user)
    post_redirect = generate_confirmation_post_redirect(user)

    url = confirm_url(email_token: post_redirect.email_token)
    UserMailer.
      already_registered(
        user,
        post_redirect.reason_params,
        url
      ).deliver_now
    render action: 'confirm' # must be same as for send_confirmation_mail above to avoid leak of presence of email in db
  end

  def assign_request_states(display_user)
    option_item = Struct.new(:value, :text)

    display_user.info_requests.pluck(:described_state).uniq.map do |state|
      option_item.new(state, InfoRequest.get_status_description(state))
    end
  end

  def set_display_user
    @display_user = User.where(email_confirmed: true).
                         friendly.find(params[:url_name])
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
      @match_phrase = _("{{search_results}} matching '{{query}}'", search_results: "", query: params[:user_query])

      unless params[:request_latest_status].blank?
        requests_query << ' latest_status:' << params[:request_latest_status]
        comments_query << ' latest_status:' << params[:request_latest_status]
        @match_phrase << _(" filtered by status: '{{status}}'", status: params[:request_latest_status])
      end
    end

    begin
      @request_results = perform_search(
        [InfoRequestEvent], requests_query,
        'newest', 'request_collapse'
      )
      @comment_results = perform_search(
        [InfoRequestEvent], comments_query, 'newest', nil
      )
    # TODO: make this rescue specific to errors thrown when xapian is not working

    rescue
      @request_results = nil
      @comment_results = nil
    end

    @page_desc = (@page > 1) ? " (page " + @page.to_s + ")" : ""

    # Track corresponding to this page
    @track_thing = TrackThing.create_track_for_user(@display_user)
    @feed_autodetect = [ { url: do_track_url(@track_thing, 'feed'), title: @track_thing.params[:title_in_rss], has_json: true } ]
  end

  def current_user_is_display_user
    @user.try(:id) == @display_user.id
  end

  # Always generate a fresh user-bound PostRedirect for confirmation emails
  def generate_confirmation_post_redirect(user)
    source_post_redirect =
      PostRedirect.find_by(token: params[:token],
                           circumstance: 'normal',
                           user: nil)

    source_post_redirect ||= generate_post_redirect_for_signup(params[:r])

    PostRedirect.create!(uri: source_post_redirect.uri,
                         post_params: source_post_redirect.post_params,
                         reason_params: source_post_redirect.reason_params,
                         circumstance: 'normal',
                         user: user)
  end

  # Redirects to front page later if nothing else specified
  def generate_post_redirect_for_signup(redirect_to="/")
    redirect_to = "/" if redirect_to.nil?
    PostRedirect.new(uri: redirect_to,
                     post_params: {},
                     reason_params: {
                       web: "",
                       email: _("Then you can sign in to {{site_name}}", site_name: site_name),
                       email_subject: _("Confirm your account on {{site_name}}", site_name: site_name)
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
      ExceptionNotifier.notify_exception(e, env: request.env)
    end

    if block_rate_limited_ips?
      flash.now[:error] =
        _("Sorry, we're currently unable to sign up new users, " \
          "please try again later")
      error = true
      render action: 'sign'
      true
    end
  end

  def spam_should_be_blocked?
    AlaveteliConfiguration.block_spam_signups ||
      AlaveteliConfiguration.enable_anti_spam
  end
end
