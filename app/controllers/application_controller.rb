# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ApplicationController < ActionController::Base
  class PermissionDenied < StandardError
  end

  class RouteNotFound < StandardError
  end

  before_action :set_gettext_locale, :store_gettext_locale
  before_action :redirect_gettext_locale, :collect_locales

  protect_from_forgery if: :authenticated?, with: :exception
  skip_before_action :verify_authenticity_token, unless: :authenticated?

  # Deal with access denied errors from CanCan
  rescue_from CanCan::AccessDenied do |_exception|
    raise PermissionDenied
  end

  # assign our own handler method for non-local exceptions
  rescue_from Exception, with: :render_exception

  # Standard headers, footers and navigation for whole site
  layout "default"

  include FastGettext::Translation # make functions like _, n_, N_ etc available)
  include AlaveteliPro::PostRedirectHandler
  include RobotsHeaders

  # NOTE: a filter stops the chain if it redirects or renders something
  before_action :html_response
  before_action :authentication_check
  before_action :check_in_post_redirect
  before_action :session_remember_me
  before_action :set_vary_header
  before_action :validate_session_timestamp
  after_action  :persist_session_timestamp

  def set_vary_header
    response.headers['Vary'] = 'Cookie'
  end

  helper_method :anonymous_cache, :short_cache, :medium_cache, :long_cache
  def anonymous_cache(time)
    return if authenticated?

    headers['Cache-Control'] = "max-age=#{time}, public"
  end

  def short_cache
    anonymous_cache(60.seconds)
  end

  def medium_cache
    anonymous_cache(60.minutes)
  end

  def long_cache
    anonymous_cache(24.hours)
  end

  # This is an override of the method provided by gettext_i18n_rails.
  # AlaveteliLocalization.set_session_locale explicitly sets I18n.locale,
  # required due to the I18nProxy used in Rails to trigger the
  # lookup_context and expire the template cache
  def set_gettext_locale
    params_locale = params[:locale]

    if AlaveteliConfiguration.use_default_browser_language
      browser_locale = request.env['HTTP_ACCEPT_LANGUAGE']
    end

    AlaveteliLocalization.set_session_locale(
      params_locale, session[:locale], cookies[:locale], browser_locale,
      AlaveteliLocalization.default_locale
    )

    # set response header informing the browser what language the page is in
    response.headers['Content-Language'] = I18n.locale.to_s
  end

  def store_gettext_locale
    # set the current stored locale to the requested_locale
    current_session_locale = session[:locale]
    if current_session_locale != AlaveteliLocalization.locale
      session[:locale] = AlaveteliLocalization.locale

      # we need to set something other than StripEmptySessions::STRIPPABLE_KEYS
      # otherwise the cookie will be striped from the response
      session[:previous_locale] = current_session_locale
    end

    # ensure current user locale attribute is up-to-date
    current_user.update_column(:locale, locale) if current_user
  end

  def redirect_gettext_locale
    # redirect to remove locale params if present
    redirect_to current_path_without_locale if params[:locale]
  end

  # Help work out which request causes RAM spike.
  # http://www.codeweblog.com/rails-to-monitor-the-process-of-memory-leaks-skills/
  # This shows the memory use increase of the Ruby process due to the request.
  # Since Ruby never returns memory to the OS, if the existing process previously
  # served a larger request, this won't show any consumption for the later request.
  # Ruby also grabs memory from the OS in variously sized jumps, so the extra
  # consumption of a request shown by this function will only appear in such
  # jumps.
  #
  # To find things that are using causing LOTS of peak memory, then do something like:
  # egrep "CONSUME MEMORY: [0-9]{7} KB" production.log
  around_action :record_memory
  def record_memory
    record_memory = AlaveteliConfiguration.debug_record_memory
    if record_memory
      logger.info "Processing request for #{request.url} with Rails process #{Process.pid}"
      File.read("/proc/#{Process.pid}/status").match(/VmRSS:\s+(\d+)/)
      rss_before_action = $1.to_i
      yield
      File.read("/proc/#{Process.pid}/status").match(/VmRSS:\s+(\d+)/)
      rss_after_action = $1.to_i
      logger.info("PID: #{Process.pid}\tCONSUME MEMORY: #{rss_after_action - rss_before_action} KB\tNow: #{rss_after_action} KB\t#{request.url}")
    else
      yield
    end
  end

  # Set cookie expiry according to "remember me" checkbox, as per "An easier
  # and more flexible hack" on this page:
  #   http://wiki.rubyonrails.org/rails/pages/HowtoChangeSessionOptions
  def session_remember_me
    # Reset the "sliding window" session expiry time.
    if request.env['rack.session.options']
      if session[:remember_me]
        request.env['rack.session.options'][:expire_after] = 1.month
      else
        request.env['rack.session.options'][:expire_after] = nil
      end
    end
  end

  # Set a TTL for non "remember me" sessions so that the cookie
  # is not replayable forever
  SESSION_TTL = 3.hours
  def validate_session_timestamp
    if session[:user_id] && session[:ttl] && session[:ttl] < SESSION_TTL.ago
      clear_session_credentials
    end
  end

  def persist_session_timestamp
    session[:ttl] = Time.zone.now if authenticated? && !session[:remember_me]
  end

  def sign_in(user, remember_me: nil)
    remember_me ||= session[:remember_me]
    clear_session_credentials
    session[:user_id] = user.id
    session[:user_login_token] = user.login_token
    session[:remember_me] = remember_me
    # Intentionally allow to fail silently so that we don't have to care whether
    # sign in recording is enabled.
    user.sign_ins.create(ip: user_ip, country: country_from_ip)
  end

  # Logout form
  def clear_session_credentials
    session[:admin_id] = nil
    session[:user_id] = nil
    session[:user_login_token] = nil
    session[:user_circumstance] = nil
    session[:remember_me] = false
    session[:using_admin] = nil
    session[:admin_name] = nil
    session[:change_password_post_redirect_id] = nil
    session[:post_redirect_token] = nil
    session[:ttl] = nil
  end

  def render_exception(exception)
    # In development let Rails handle the exception with its stack trace
    # templates.
    raise exception if Rails.application.config.consider_all_requests_local

    @exception_backtrace = exception.backtrace.join("\n")
    @exception_class = exception.class.to_s
    @exception_message = exception.message
    case exception
    when ActiveRecord::RecordNotFound, RouteNotFound, WillPaginate::InvalidPage
      @status = 404
      sanitize_path(params)
    when PermissionDenied
      @status = 403
    when ActionController::UnknownFormat
      @status = 406
    else
      message = "\n#{@exception_class} (#{@exception_message}):\n"
      backtrace = Rails.backtrace_cleaner.clean(exception.backtrace, :silent)
      message << "  " << backtrace.join("\n  ")
      Rails.logger.fatal("#{message}\n\n")
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(exception, env: request.env)
      end
      @status = 500
    end
    respond_to do |format|
      format.html { render template: "general/exception_caught", status: @status }
      format.any { head @status }
    end
  end

  def render_hidden(template='request/hidden', opts = {})
    # An embargoed is totally hidden - no indication that anything exists there
    # to see
    raise ActiveRecord::RecordNotFound if @info_request && @info_request.embargo

    response_code = opts.delete(:response_code) { 403 } # forbidden
    options = { template: template, status: response_code }.merge(opts)

    respond_to do |format|
      format.html { render(options) }
      format.any { head response_code }
    end
    false
  end

  # A helper method to set @in_pro_area, for controller actions which are
  # used in both a pro and non-pro context and depend on the :pro parameter
  # to know which one they're displaying.
  # Intended to be used as a before_action, see RequestController for example
  # usage.
  def set_in_pro_area
    @in_pro_area = params[:pro] == "1" && current_user.present? && current_user.is_pro?
  end

  private

  # Override the Rails method to only set the CSRF form token if there is a
  # logged in user
  def form_authenticity_token(**args)
    super if authenticated?
  end

  # Check the user is logged in
  def authenticated?(as: nil)
    if as
      authenticated_user == as
    else
      authenticated_user.present?
    end
  end

  def ask_to_login(as: nil, **reason_params)
    if as
      reason_params[:user_name] = as.name
      reason_params[:user_url] = show_user_url(url_name: as.url_name)

      if authenticated?
        # They are already logged in, but as the wrong user
        @reason_params = reason_params
        render(template: 'user/wrong_user') && return
      end
    end

    post_redirect = reason_params.delete(:post_redirect)
    post_redirect ||= PostRedirect.new(uri: request.fullpath,
                                       post_params: params,
                                       reason_params: reason_params)
    post_redirect.save!

    # Make sure this redirect does not get cached - it only applies to this user
    # HTTP 1.1
    headers['Cache-Control'] = 'private, no-cache, no-store, max-age=0, must-revalidate'
    # HTTP 1.0
    headers['Pragma'] = 'no-cache'
    # Proxies
    headers['Expires'] = '0'

    # 'modal' controls whether the sign-in form will be displayed in the typical
    # full-blown page or on its own, useful for pop-ups
    redirect_to signin_url(token: post_redirect.token, modal: params[:modal])

    false
  end

  # Return logged in user
  def authenticated_user
    return unless session[:user_id]
    @user ||= User.authenticate_from_session(session)
  end

  # For CanCanCan and other libs which need a Devise-like current_user method
  alias current_user authenticated_user
  helper_method :current_user

  # Do a POST redirect. This is a nasty hack - we store the posted values in
  # the session, and when the GET redirect with "?post_redirect=1" happens,
  # load them in.
  def do_post_redirect(post_redirect, user=nil)
    uri = SafeRedirect.new(post_redirect.uri).path
    if feature_enabled?(:alaveteli_pro) &&
       user &&
       user.is_pro? &&
       session[:admin_confirmation] != 1
      uri = override_post_redirect_for_pro(uri,
                                           post_redirect,
                                           user)
    end
    session[:post_redirect_token] = post_redirect.token
    uri = add_post_redirect_param_to_uri(uri)
    session.delete(:admin_confirmation)
    redirect_to uri
  end

  def add_post_redirect_param_to_uri(uri)
    add_query_params_to_url(uri, post_redirect: 1)
  end

  # If we are in a faked redirect to POST request, then set post params.
  def check_in_post_redirect
    if params[:post_redirect]
      if session[:post_redirect_token]
        post_redirect =
          PostRedirect.find_by_token(session[:post_redirect_token])
        if post_redirect
          post_redirect_params =
            params_to_unsafe_hash(post_redirect.post_params)
          params.merge!(post_redirect_params)
          params[:post_redirect_user] = post_redirect.user
        end
      else
        logger.warn "Missing post redirect token. " \
                    "Session: #{session.to_hash} " \
                    "IP: #{user_ip} " \
                    "Params: #{params}"
      end
    end
  end

  def html_response
    respond_to :html
  end

  # Default layout shows user in corner, so needs access to it
  def authentication_check
    @user ||= authenticated_user
  end

  #
  def check_read_only
    unless AlaveteliConfiguration.read_only.empty?
      if feature_enabled?(:annotations)
        flash[:notice] = {
          partial: "general/read_only_annotations",
          locals: {
            site_name: site_name,
            read_only: AlaveteliConfiguration.read_only
          }
        }
      else
        flash[:notice] = {
          partial: "general/read_only",
          locals: {
            site_name: site_name,
            read_only: AlaveteliConfiguration.read_only
          }
        }
      end
      redirect_to frontpage_url
    end
  end

  # Convert URL name for sort by order, to Xapian query
  def order_to_sort_by(sortby)
    if sortby.nil?
      [nil, nil]
    elsif sortby == 'newest'
      ['created_at', true]
    elsif sortby == 'described'
      ['described_at', true] # use this for some RSS
    elsif sortby == 'relevant'
      [nil, nil]
    else
      raise "Unknown sort order " + @sortby
    end
  end

  # Function for search
  def perform_search(models, query, sortby, collapse, per_page = 25, this_page = nil)
    @query = query
    @sortby = sortby

    # Work out sorting method
    order, ascending = order_to_sort_by(@sortby)

    # Perform the search
    @per_page = per_page
    @page = this_page || get_search_page_from_params

    result = ActsAsXapian::Search.new(models, @query,
                                      offset: (@page - 1) * @per_page,
                                      limit: @per_page,
                                      sort_by_prefix: order,
                                      sort_by_ascending: ascending,
                                      collapse_by_prefix: collapse
                                      )
    result.results # Touch the results to load them, otherwise accessing them from the view
    # might fail later if the database has subsequently been reopened.
    result
  end

  def get_search_page_from_params
    page = (params[:page] || "1").to_i
    page = 1 if page < 1
    page
  end

  def typeahead_search(query, options)
    @page = get_search_page_from_params
    @per_page = options[:per_page] || 25
    options.merge!( page: @page,
                    per_page: @per_page )
    typeahead_search = TypeaheadSearch.new(query, options)
    typeahead_search.xapian_search
  end

  # Store last visited pages, for contact form; but only for logged in users, as otherwise this breaks caching
  def set_last_request(info_request)
    return unless authenticated?

    cookies["last_request_id"] = info_request.id
    cookies["last_body_id"] = nil
  end

  def set_last_body(public_body)
    return unless authenticated?

    cookies["last_request_id"] = nil
    cookies["last_body_id"] = public_body.id
  end

  def country_from_ip
    return AlaveteliGeoIP.country_code_from_ip(user_ip) if user_ip

    AlaveteliConfiguration.iso_country_code
  end

  def user_ip
    request.remote_ip
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError
    nil
  end

  # URL Encode the path parameter for use in render_exception
  #
  # params - the params Hash
  #
  # Returns a Hash
  def sanitize_path(params)
    params.merge!(path: Rack::Utils.escape(params[:path])) if params.key?(:path)
  end

  # Collect the current and available locales for the locale switcher
  #
  # Returns a Hash
  def collect_locales
    @locales = { current: AlaveteliLocalization.locale, available: [] }
    AlaveteliLocalization.available_locales.each do |possible_locale|
      if possible_locale == AlaveteliLocalization.locale
        @locales[:current] = possible_locale
      else
        @locales[:available] << possible_locale
      end
    end
  end

  # URL generating functions are needed by all controllers (for redirects),
  # views (for links) and mailers (for use in emails), so include them into
  # all of all.
  include LinkToHelper

  # Site-wide access to configuration settings
  include ConfigHelper

  include HashableParams
end
