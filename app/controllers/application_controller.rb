# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.59 2009-09-17 13:01:56 francis Exp $


class ApplicationController < ActionController::Base
    # Standard headers, footers and navigation for whole site
    layout "default"
    include FastGettext::Translation # make functions like _, n_, N_ etc available)
    before_filter :set_gettext_locale

    # scrub sensitive parameters from the logs
    filter_parameter_logging :password


    def set_gettext_locale
        requested_locale = params[:locale] || session[:locale] || cookies[:locale] ||  request.env['HTTP_ACCEPT_LANGUAGE']
        session[:locale] = FastGettext.set_locale(requested_locale)
    end

    # scrub sensitive parameters from the logs
    filter_parameter_logging :password

    helper_method :site_name, :locale_from_params
    def site_name
      site_name = MySociety::Config.get('SITE_NAME', 'Alaveteli')
      return site_name      
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
    around_filter :record_memory
    def record_memory
        record_memory = MySociety::Config.get('DEBUG_RECORD_MEMORY', false)
        if record_memory
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
    before_filter :session_remember_me
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

    # Override default error handler, for production sites.
    def rescue_action_in_public(exception)
        # Make sure expiry time for session is set (before_filters are
        # otherwise missed by this override) 
        session_remember_me

        # Display user appropriate error message
        @exception_backtrace = exception.backtrace.join("\n")
        @exception_class = exception.class.to_s
        render :template => "general/exception_caught.rhtml", :status => 404
    end

    # For development sites.
    alias original_rescue_action_locally rescue_action_locally
    def rescue_action_locally(exception)
        # Make sure expiry time for session is set (before_filters are
        # otherwise missed by this override) 
        session_remember_me

        # Display default, detailed error for developers
        original_rescue_action_locally(exception)
    end
      
    def local_request?
        false
    end

    # Called from test code, is a mimic of User.confirm, for use in following email
    # links when in controller tests (since we don't have full integration tests that
    # can work over multiple controllers)
    def test_code_redirect_by_email_token(token, controller_example_group)
        post_redirect = PostRedirect.find_by_email_token(token)
        if post_redirect.nil?
            raise "bad token in test code email"
        end
        session[:user_id] = post_redirect.user.id
        session[:user_circumstance] = post_redirect.circumstance
        params = controller_example_group.params_from(:get, post_redirect.local_part_uri)
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
        path = foi_fragment_cache_part_path(param)
        path = "/views" + path
        foi_cache_path = File.join(File.dirname(__FILE__), '../../cache')
        return File.join(foi_cache_path, path)
    end
    def foi_fragment_cache_all_for_request(info_request)
        # return stub path so admin can expire it
        first_three_digits = info_request.id.to_s()[0..2]
        path = "views/request/#{first_three_digits}/#{info_request.id}"
        foi_cache_path = File.join(File.dirname(__FILE__), '../../cache')
        return File.join(foi_cache_path, path)
    end
    def foi_fragment_cache_exists?(key_path)
        return File.exists?(key_path)
    end
    def foi_fragment_cache_read(key_path)
        cached = File.read(key_path)
    end
    def foi_fragment_cache_write(key_path, content)
        FileUtils.mkdir_p(File.dirname(key_path))
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

    # Check the user is logged in
    def authenticated?(reason_params)
        unless session[:user_id]
            post_redirect = PostRedirect.new(:uri => request.request_uri, :post_params => params,
                :reason_params => reason_params)
            post_redirect.save!
            redirect_to signin_url(:token => post_redirect.token)
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
            return User.find(session[:user_id])
        end
    end

    # Do a POST redirect. This is a nasty hack - we store the posted values in
    # the session, and when the GET redirect with "?post_redirect=1" happens,
    # load them in.
    def do_post_redirect(post_redirect)
        uri = post_redirect.uri

        session[:post_redirect_token] = post_redirect.token

        # XXX what is the built in Ruby URI munging function that can do this
        # choice of & vs. ? more elegantly than this dumb if statement?
        if uri.include?("?")
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
    before_filter :check_in_post_redirect
    def check_in_post_redirect
        if params[:post_redirect] and session[:post_redirect_token]
            post_redirect = PostRedirect.find_by_token(session[:post_redirect_token])
            params.update(post_redirect.post_params)
        end
    end

    # Default layout shows user in corner, so needs access to it
    before_filter :authentication_check
    def authentication_check
        if session[:user_id]
            @user = authenticated_user
        end
    end

    # 
    def check_read_only
        read_only = MySociety::Config.get('READ_ONLY', '')
        if !read_only.empty?
            flash[:notice] = "<p>WhatDoTheyKnow is currently in maintenance. You can only view existing requests. You cannot make new ones, add followups or annotations, or otherwise change the database.</p> <p>" + read_only + "</p>"
            redirect_to frontpage_url
        end

    end

    # For administration interface, return display name of authenticated user
    def admin_http_auth_user
        # This needs special magic in mongrel: http://www.ruby-forum.com/topic/83067
        # Hence the second clause which reads X-Forwarded-User header if available.
        # See the rewrite rules in conf/httpd.conf which set X-Forwarded-User
        if request.env["REMOTE_USER"]
            return request.env["REMOTE_USER"]
        elsif request.env["HTTP_X_FORWARDED_USER"]
            return request.env["HTTP_X_FORWARDED_USER"]
        else
            return "*unknown*";
        end
    end
    def assign_http_auth_user
        @http_auth_user = admin_http_auth_user
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
        order_pair = order_to_sort_by(@sortby)
        order = order_pair[0]
        ascending = order_pair[1]

        # Peform the search
        @per_page = per_page
        if this_page.nil?
            @page = get_search_page_from_params
        else
            @page = this_page
        end
        return InfoRequest.full_search(models, @query, order, ascending, collapse, @per_page, @page) 
    end
    def get_search_page_from_params
        return (params[:page] || "1").to_i
    end

    # Store last visited pages, for contact form
    def set_last_request(info_request)
        session[:last_request_id] = info_request.id
        session[:last_body_id] = nil
    end
    def set_last_body(public_body)
        session[:last_request_id] = nil
        session[:last_body_id] = public_body.id
    end

    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper
end


