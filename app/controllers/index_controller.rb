# controllers/index_controller.rb:
# Main page of site.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: index_controller.rb,v 1.2 2007-10-09 17:29:43 francis Exp $

class IndexController < ApplicationController
    def index
        respond_to do |format|
            format.html
        end
    end

    private

end

