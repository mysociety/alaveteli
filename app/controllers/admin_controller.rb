# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.29 2009-09-17 10:24:35 francis Exp $

require 'fileutils'

class AdminController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

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
    end

    # Expire cached attachment files for a user
    def expire_requests_for_user(user)
        for info_request in user.info_requests
            expire_for_request(info_request)
        end
    end
end

