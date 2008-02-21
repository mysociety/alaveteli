# app/controllers/admin_public_body_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_public_body_controller.rb,v 1.7 2008-02-21 16:15:45 francis Exp $

class AdminPublicBodyController < ApplicationController
    layout "admin"

    def index
        list
        render :action => 'list'
    end

    def list
        @public_bodies = PublicBody.paginate :order => "name", :page => params[:page], :per_page => 100
    end

    def show
        @public_body = PublicBody.find(params[:id])
    end

    def new
        @public_body = PublicBody.new
    end

    def create
        params[:public_body][:last_edit_editor] = admin_http_auth_user()
        @public_body = PublicBody.new(params[:public_body])
        if @public_body.save
            flash[:notice] = 'PublicBody was successfully created.'
            redirect_to admin_url('body/list')
        else
            render :action => 'new'
        end
    end

    def edit
        @public_body = PublicBody.find(params[:id])
        @public_body.last_edit_comment = ""
    end

    def update
        params[:public_body][:last_edit_editor] = admin_http_auth_user()
        @public_body = PublicBody.find(params[:id])
        if @public_body.update_attributes(params[:public_body])
            flash[:notice] = 'PublicBody was successfully updated.'
            redirect_to admin_url('body/show/' + @public_body.id.to_s)
        else
            render :action => 'edit'
        end
    end

    def destroy
        PublicBody.find(params[:id]).destroy
        flash[:notice] = "PublicBody was successfully destroyed."
        redirect_to admin_url('body/list')
    end

    private

end
