# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.1 2007-10-09 11:30:01 francis Exp $

class RequestController < ApplicationController

    def index
        @info_request = InfoRequest.find(params[:id])
    end

end
