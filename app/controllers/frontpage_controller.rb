# controllers/frontpage_controller.rb:
# Main page of site.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: frontpage_controller.rb,v 1.2 2007-08-01 16:41:32 francis Exp $

class FrontpageController < ApplicationController
    layout "default"

    def index
        respond_to do |format|
            format.html
        end
    end

    before_filter :check_authentication, :except => [:signin]
end

