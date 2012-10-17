# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

require 'fileutils'

class AdminController < ApplicationController
    layout "admin"
    before_filter :authenticate
    protect_from_forgery # See ActionController::RequestForgeryProtection for details

    # action to take if expecting an authenticity token and one isn't received
    def handle_unverified_request
        raise(ActionController::InvalidAuthenticityToken)
    end

    # Always give full stack trace for admin interface
    def local_request?
        true
    end

    # Expire cached attachment files for a request
    def expire_for_request(info_request)
        # Clear out cached entries, by removing files from disk (the built in
        # Rails fragment cache made doing this and other things too hard)
        cache_subpath = foi_fragment_cache_all_for_request(info_request)
        FileUtils.rm_rf(cache_subpath)

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

    def authenticate
        if Configuration::skip_admin_auth
            session[:using_admin] = 1
            return
        else
            if session[:using_admin].nil?
                if params[:emergency].nil?
                    if authenticated?(
                                      :web => _("To log into the administrative interface"),
                                      :email => _("Then you can log into the administrative interface"),
                                      :email_subject => _("Log into the admin interface"),
                                      :user_name => "a superuser")
                        if !@user.nil? && @user.admin_level == "super"
                            session[:using_admin] = 1
                            request.env['REMOTE_USER'] = @user.url_name
                        else

                            session[:using_admin] = nil
                            session[:user_id] = nil
                            self.authenticate
                        end
                    end
                else
                    authenticate_or_request_with_http_basic do |user_name, password|
                        if user_name == Configuration::admin_username && password == Configuration::admin_password
                            session[:using_admin] = 1
                            request.env['REMOTE_USER'] = user_name
                        else
                            request_http_basic_authentication
                        end
                    end
                end
            end
        end
    end
end

