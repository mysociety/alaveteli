# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.3 2007-08-23 17:39:42 francis Exp $

class FileRequestController < ApplicationController
    def index
    end

    def create
        @info_request = InfoRequest.new(params[:info_request])

        if not @info_request.save
            render :action => 'index'
        else
            # render create action
        end
    end


end


