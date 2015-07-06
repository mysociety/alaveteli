# -*- encoding : utf-8 -*-
# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'fileutils'

class AdminController < ApplicationController
    layout "admin"
    before_filter :authenticate

    # action to take if expecting an authenticity token and one isn't received
    def handle_unverified_request
        raise(ActionController::InvalidAuthenticityToken)
    end

    # Always give full stack trace for admin interface
    def show_rails_exceptions?
        true
    end

    # Expire cached attachment files for a request
    def expire_for_request(info_request)
        # Clear out cached entries, by removing files from disk (the built in
        # Rails fragment cache made doing this and other things too hard)
        info_request.foi_fragment_cache_directories.each{ |dir| FileUtils.rm_rf(dir) }

        # Remove any download zips
        FileUtils.rm_rf(info_request.download_zip_dir)

        # Remove the database caches of body / attachment text (the attachment text
        # one is after privacy rules are applied)
        info_request.clear_in_database_caches!

        # also force a search reindexing (so changed text reflected in search)
        info_request.reindex_request_events
        # and remove from varnish
        info_request.purge_in_cache
    end

    # Expire cached attachment files for a user
    def expire_requests_for_user(user)
        for info_request in user.info_requests
            expire_for_request(info_request)
        end
    end

    # For administration interface, return display name of authenticated user
    def admin_current_user
        if AlaveteliConfiguration::skip_admin_auth
            admin_http_auth_user
        else
            session[:admin_name]
        end
    end

    # If we're skipping Alaveteli admin authentication, assume that the environment
    # will give us an authenticated user name
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

    def authenticate
        if AlaveteliConfiguration::skip_admin_auth
            session[:using_admin] = 1
            return
        else
            if session[:using_admin].nil? || session[:admin_name].nil?
                if params[:emergency].nil? || AlaveteliConfiguration::disable_emergency_user
                    if authenticated?(
                                      :web => _("To log into the administrative interface"),
                                      :email => _("Then you can log into the administrative interface"),
                                      :email_subject => _("Log into the admin interface"),
                                      :user_name => "a superuser")
                        if !@user.nil? && @user.admin_level == "super"
                            session[:using_admin] = 1
                            session[:admin_name] = @user.url_name
                        else
                            session[:using_admin] = nil
                            session[:user_id] = nil
                            session[:admin_name] = nil
                            self.authenticate
                        end
                    end
                else
                    authenticate_or_request_with_http_basic do |user_name, password|
                        if user_name == AlaveteliConfiguration::admin_username && password == AlaveteliConfiguration::admin_password
                            session[:using_admin] = 1
                            session[:admin_name] = user_name
                        else
                            request_http_basic_authentication
                        end
                    end
                end
            end
        end
    end
end

