# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.23 2009-01-29 12:10:10 francis Exp $


class AdminController < ActionController::Base
    layout "admin"
    before_filter :assign_http_auth_user

    # Always give full stack trace for admin interface
    def local_request?
        true
    end
end
