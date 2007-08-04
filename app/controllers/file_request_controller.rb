# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.1 2007-08-04 11:10:25 francis Exp $

class FileRequestController < ApplicationController
    def index
        respond_to do |format|
            format.html
        end
    end

    def create
        respond_to do |format|
            format.html
        end
    end


end


