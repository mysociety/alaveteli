# controllers/frontpage_controller.rb:
# Main page of site.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: frontpage_controller.rb,v 1.4 2007-08-04 11:10:25 francis Exp $

class FrontpageController < ApplicationController
    def index
        respond_to do |format|
            format.html
        end
    end

    #before_filter :check_authentication, :except => [:signin]
end

