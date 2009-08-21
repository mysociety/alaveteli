# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.27 2009-08-21 17:43:33 francis Exp $


class AdminController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    # Always give full stack trace for admin interface
    def local_request?
        true
    end

    # Expire cached attachment files for a request
    def expire_for_request(info_request)
        # Clear out cached entries - use low level expire_fragment, even though
        # we are clearing results from caches_action, for several reasons:
        # * We can't use expire_action here, as doesn't  seem to be
        # compatible with the :only_path we used in the caches_action
        # call. 
        # * expire_fragment lets us use a regular expression which is
        # simpler than having to get all the parameters right for the
        # path, and calling for HTML version vs. raw attachment version.
        # * Regular expression means we cope properly with filenames
        # changed by censor rules, which change the URL.
        # * It's also possible to load a file with any name by changing
        # the URL, the regular expression makes sure the cache is
        # cleared even if someone did that.
        expire_fragment /views\/request\/#{info_request.id}.*/
        # also force a search reindexing (so changed text reflected in search)
        info_request.reindex_request_events
    end
end

