# -*- coding: utf-8 -*-
# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'open-uri'

class ApplicationController < ActionController::Base
    class PermissionDenied < StandardError
    end
    class RouteNotFound < StandardError
    end
    protect_from_forgery :if => :user?
    skip_before_filter :verify_authenticity_token, :unless => :user?

    # assign our own handler method for non-local exceptions
    rescue_from Exception, :with => :render_exception

    # Add some security-related headers (see config/initializers/secure_headers.rb)
    ensure_security_headers

    # Standard headers, footers and navigation for whole site
    layout "default"
    include FastGettext::Translation # make functions like _, n_, N_ etc available)

    # Note: a filter stops the chain if it redirects or renders something
    before_filter :authentication_check
    before_filter :set_gettext_locale
    before_filter :check_in_post_redirect
    before_filter :session_remember_me
    before_filter :set_vary_header
    before_filter :validate_session_timestamp
    after_filter  :persist_session_timestamp

    def set_vary_header
        response.headers['Vary'] = 'Cookie'
    end

    helper_method :anonymous_cache, :short_cache, :medium_cache, :long_cache
    def anonymous_cache(time)
        if session[:user_id].nil?
            expires_in time, :public => true
        end
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

    # This is an override of the method provided by gettext_i18n_rails - note the explicit
    # setting of I18n.locale, required due to the I18nProxy used in Rails 3 to trigger the
    # lookup_context and expire the template cache
    def set_gettext_locale
        if AlaveteliConfiguration::include_default_locale_in_urls == false
            params_locale = params[:locale] ? params[:locale] : I18n.default_locale
        else
            params_locale = params[:locale]
        end
        if AlaveteliConfiguration::use_default_browser_language
            requested_locale = params_locale || session[:locale] || cookies[:locale] || request.env['HTTP_ACCEPT_LANGUAGE'] || I18n.default_locale
        else
            requested_locale = params_locale || session[:locale] || cookies[:locale] || I18n.default_locale
        end
        requested_locale = FastGettext.best_locale_in(requested_locale)
        session[:locale] = I18n.locale = FastGettext.set_locale(requested_locale)
        if !@user.nil?
            if @user.locale != requested_locale
                @user.locale = session[:locale]
                @user.save!
            end
        end
    end

    helper_method :locale_from_params

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
    around_filter :record_memory
    def record_memory
        record_memory = AlaveteliConfiguration::debug_record_memory
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
        if session[:user_id] && session.key?(:ttl) && session[:ttl] < SESSION_TTL.ago
            clear_session_credentials
            redirect_to signin_path
        end
    end

    def persist_session_timestamp
        session[:ttl] = Time.now if session[:user_id] && !session[:remember_me]
    end

    # Logout form
    def clear_session_credentials
        session[:user_id] = nil
        session[:user_circumstance] = nil
        session[:remember_me] = false
        session[:using_admin] = nil
        session[:admin_name] = nil
    end

    def render_exception(exception)
        # In development or the admin interface let Rails handle the exception
        # with its stack trace templates
        if Rails.application.config.consider_all_requests_local || show_rails_exceptions?
            raise exception
        end

        @exception_backtrace = exception.backtrace.join("\n")
        @exception_class = exception.class.to_s
        @exception_message = exception.message
        case exception
        when ActiveRecord::RecordNotFound, RouteNotFound, WillPaginate::InvalidPage
            @status = 404
            sanitize_path(params)
        when PermissionDenied
            @status = 403
        else
            message = "\n#{@exception_class} (#{@exception_message}):\n"
            backtrace = Rails.backtrace_cleaner.clean(exception.backtrace, :silent)
            message << "  " << backtrace.join("\n  ")
            Rails.logger.fatal("#{message}\n\n")
            if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
                ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
            end
            @status = 500
        end
        respond_to do |format|
            format.html{ render :template => "general/exception_caught", :status => @status }
            format.any{ render :nothing => true, :status => @status }
        end
    end

    def show_rails_exceptions?
        false
    end

    # Called from test code, is a mimic of UserController.confirm, for use in following email
    # links when in controller tests (though we also have full integration tests that
    # can work over multiple controllers)
    # TODO: Move this to the tests. It shouldn't be here
    def test_code_redirect_by_email_token(token, controller_example_group)
        post_redirect = PostRedirect.find_by_email_token(token)
        if post_redirect.nil?
            raise "bad token in test code email"
        end
        session[:user_id] = post_redirect.user.id
        session[:user_circumstance] = post_redirect.circumstance
        params = Rails.application.routes.recognize_path(post_redirect.local_part_uri)
        params.merge(post_redirect.post_params)
        controller_example_group.get params[:action], params
    end

    # Used to work out where to cache fragments. We add an extra path to the
    # URL using the first three digits of the info request id, because we can't
    # have more than 32,000 entries in one directory on an ext3 filesystem.
    def foi_fragment_cache_part_path(param)
        path = url_for(param)
        id = param['id'] || param[:id]
        first_three_digits = id.to_s()[0..2]
        path = path.sub("/request/", "/request/" + first_three_digits + "/")
        return path
    end

    def foi_fragment_cache_path(param)
        path = File.join(Rails.root, 'cache', 'views', foi_fragment_cache_part_path(param))
        max_file_length = 255 - 35 # we subtract 35 because tempfile
                                   # adds on a variable number of
                                   # characters
        return File.join(File.split(path).map{|x| x[0...max_file_length]})
    end

    def foi_fragment_cache_exists?(key_path)
        return File.exists?(key_path)
    end

    def foi_fragment_cache_read(key_path)
        logger.info "Reading from fragment cache #{key_path}"
        return File.read(key_path)
    end

    def foi_fragment_cache_write(key_path, content)
        FileUtils.mkdir_p(File.dirname(key_path))
        logger.info "Writing to fragment cache #{key_path}"
        File.atomic_write(key_path) do |f|
            f.write(content)
        end
    end

    # get the local locale
    def locale_from_params(*args)
      if params[:show_locale]
        params[:show_locale]
      else
        I18n.locale.to_s
      end
    end

    private

    def user?
        !session[:user_id].nil?
    end

    def form_authenticity_token
        if user?
            session[:_csrf_token] ||= SecureRandom.base64(32)
        end
    end

    # Check the user is logged in
    def authenticated?(reason_params)
        unless session[:user_id]
            post_redirect = PostRedirect.new(:uri => request.fullpath, :post_params => params,
                :reason_params => reason_params)
            post_redirect.save!
            # 'modal' controls whether the sign-in form will be displayed in the typical full-blown
            # page or on its own, useful for pop-ups
            redirect_to signin_url(:token => post_redirect.token, :modal => params[:modal])
            return false
        end
        return true
    end

    def authenticated_as_user?(user, reason_params)
        reason_params[:user_name] = user.name
        reason_params[:user_url] = show_user_url(:url_name => user.url_name)
        if session[:user_id]
            if session[:user_id] == user.id
                # They are logged in as the right user
                return true
            else
                # They are already logged in, but as the wrong user
                @reason_params = reason_params
                render :template => 'user/wrong_user'
                return
            end
        end
        # They are not logged in at all
        return authenticated?(reason_params)
    end

    # Return logged in user
    def authenticated_user
        if session[:user_id].nil?
            return nil
        else
            begin
                return User.find(session[:user_id])
            rescue ActiveRecord::RecordNotFound
                return nil
            end
        end
    end

    # Do a POST redirect. This is a nasty hack - we store the posted values in
    # the session, and when the GET redirect with "?post_redirect=1" happens,
    # load them in.
    def do_post_redirect(post_redirect)
        uri = post_redirect.uri

        session[:post_redirect_token] = post_redirect.token

        # TODO: what is the built in Ruby URI munging function that can do this
        # choice of & vs. ? more elegantly than this dumb if statement?
        if uri.include?("?")
            # TODO: This looks odd. What would a fragment identifier be doing server-side?
            #     But it also looks harmless, so I’ll leave it just in case.
            if uri.include?("#")
                uri.sub!("#", "&post_redirect=1#")
            else
                uri += "&post_redirect=1"
            end
        else
            if uri.include?("#")
                uri.sub!("#", "?post_redirect=1#")
            else
                uri += "?post_redirect=1"
            end
        end
        redirect_to uri
    end

    # If we are in a faked redirect to POST request, then set post params.
    def check_in_post_redirect
        if params[:post_redirect] and session[:post_redirect_token]
            post_redirect = PostRedirect.find_by_token(session[:post_redirect_token])
            params.update(post_redirect.post_params)
            params[:post_redirect_user] = post_redirect.user
        end
    end

    # Default layout shows user in corner, so needs access to it
    def authentication_check
        if session[:user_id]
            @user = authenticated_user
        end
    end

    #
    def check_read_only
        if !AlaveteliConfiguration::read_only.empty?
            flash[:notice] = _("<p>{{site_name}} is currently in maintenance. You can only view existing requests. You cannot make new ones, add followups or annotations, or otherwise change the database.</p> <p>{{read_only}}</p>",
                :site_name => site_name,
                :read_only => AlaveteliConfiguration::read_only)
            redirect_to frontpage_url
        end

    end

    # Convert URL name for sort by order, to Xapian query
    def order_to_sort_by(sortby)
        if sortby.nil?
            return [nil, nil]
        elsif sortby == 'newest'
            return ['created_at', true]
        elsif sortby == 'described'
            return ['described_at', true] # use this for some RSS
        elsif sortby == 'relevant'
            return [nil, nil]
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

        # Peform the search
        @per_page = per_page
        @page = this_page || get_search_page_from_params

        result = ActsAsXapian::Search.new(models, @query,
            :offset => (@page - 1) * @per_page,
            :limit => @per_page,
            :sort_by_prefix => order,
            :sort_by_ascending => ascending,
            :collapse_by_prefix => collapse
        )
        result.results # Touch the results to load them, otherwise accessing them from the view
                       # might fail later if the database has subsequently been reopened.
        return result
    end

    def get_search_page_from_params
        page = (params[:page] || "1").to_i
        page = 1 if page < 1
        return page
    end

    def perform_search_typeahead(query, model, per_page=25)
        @page = get_search_page_from_params
        @per_page = per_page
        query_words = query.split(/ +(?![-+]+)/)
        if query_words.last.nil? || query_words.last.strip.length < 3
            xapian_requests = nil
        else
            if model == PublicBody
                collapse = nil
            elsif model == InfoRequestEvent
                collapse = 'request_collapse'
            end
            options = {
                :offset => (@page - 1) * @per_page,
                :limit => @per_page,
                :sort_by_prefix => nil,
                :sort_by_ascending => true,
                :collapse_by_prefix => collapse,
            }
            ActsAsXapian.readable_init
            old_default_op = ActsAsXapian.query_parser.default_op
            ActsAsXapian.query_parser.default_op = Xapian::Query::OP_OR
            begin
                user_query =  ActsAsXapian.query_parser.parse_query(
                                           query.strip + '*',
                                           Xapian::QueryParser::FLAG_LOVEHATE | Xapian::QueryParser::FLAG_WILDCARD |
                                           Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
                xapian_requests = ActsAsXapian::Search.new([model], query, options, user_query)
            rescue RuntimeError => e
                if e.message =~ /^QueryParserError: Wildcard/
                    # Wildcard expands to too many terms
                    logger.info "Wildcard query '#{query.strip + '*'}' caused: #{e.message}"

                    user_query =  ActsAsXapian.query_parser.parse_query(
                                               query,
                                               Xapian::QueryParser::FLAG_LOVEHATE |
                                               Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
                    xapian_requests = ActsAsXapian::Search.new([model], query, options, user_query)
                end
            end
            ActsAsXapian.query_parser.default_op = old_default_op
        end
        return xapian_requests
    end

    # Store last visited pages, for contact form; but only for logged in users, as otherwise this breaks caching
    def set_last_request(info_request)
        if !session[:user_id].nil?
            cookies["last_request_id"] = info_request.id
            cookies["last_body_id"] = nil
        end
    end
    def set_last_body(public_body)
        if !session[:user_id].nil?
            cookies["last_request_id"] = nil
            cookies["last_body_id"] = public_body.id
        end
    end

    def country_from_ip
        country = ""
        if !AlaveteliConfiguration::gaze_url.empty?
            begin
                country = quietly_try_to_open("#{AlaveteliConfiguration::gaze_url}/gaze-rest?f=get_country_from_ip;ip=#{request.remote_ip}")
            rescue ActionDispatch::RemoteIp::IpSpoofAttackError
                country = AlaveteliConfiguration::iso_country_code
            end
        end
        country = AlaveteliConfiguration::iso_country_code if country.empty?
        return country
    end

    def alaveteli_git_commit
      `git log -1 --format="%H"`.strip
    end

    # URL Encode the path parameter for use in render_exception
    #
    # params - the params Hash
    #
    # Returns a Hash
    def sanitize_path(params)
        params.merge!(:path => Rack::Utils.escape(params[:path])) if params.key?(:path)
    end

    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper

    # Site-wide access to configuration settings
    include ConfigHelper
end


