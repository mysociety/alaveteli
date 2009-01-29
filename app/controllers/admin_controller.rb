# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.24 2009-01-29 12:23:25 francis Exp $


class AdminController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    # Always give full stack trace for admin interface
    def local_request?
        true
    end
end
