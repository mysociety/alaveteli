# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.2 2007-08-21 11:33:45 francis Exp $

class FileRequestController < ApplicationController
    def index
        respond_to do |format|
            format.html
        end
    end

    def create
        @info_request = InfoRequest.new(params[:info_request])
        @info_request.save

        #redirect_to(:action => 'index')
        render :action => 'index'

#        respond_to do |format|
#            format.html
#        end

    end


end


