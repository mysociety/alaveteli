# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.28 2009-09-15 20:46:35 francis Exp $

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
        # Clear out cached entries - use low level disk removal, even though we
        # are clearing results from caches_action, for several reasons:
        # * We can't use expire_action here, as it doesn't seem to be
        # compatible with the :only_path we used in the caches_action
        # call. 
        # * Removing everything is simpler than having to get all the
        # parameters right for the path, and calling for HTML version vs. raw
        # attachment version.
        # * We cope properly with filenames changed by censor rules, which
        # change the URL.
        # * We could use expire_fragment with a Regexp, but it walks the whole
        # cache which is insanely slow
        cache_subpath = File.join(self.cache_store.cache_path, "views/request/#{info_request.id}")
        FileUtils.rm_rf(cache_subpath)

        # also force a search reindexing (so changed text reflected in search)
        info_request.reindex_request_events
    end
end

