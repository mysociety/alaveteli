# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.4 2007-09-10 01:16:35 francis Exp $

class FileRequestController < ApplicationController
    def index
    end

    def create
#        raise params[:info_request][:public_body_id]
#        params[:info_request][:public_body] = PublicBody.find(params[:info_request][:public_body_id])
#        params[:info_request].delete(:public_body_id)
        @info_request = InfoRequest.new(params[:info_request])

        if not @info_request.save
            render :action => 'index'
        else
            # render create action
        end
    end


end


