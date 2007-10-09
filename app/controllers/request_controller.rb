# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.2 2007-10-09 17:29:43 francis Exp $

class RequestController < ApplicationController
    def index
        @info_request = InfoRequest.find(params[:id])
    end

    private

end
