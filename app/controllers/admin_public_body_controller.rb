# app/controllers/admin_public_body_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_public_body_controller.rb,v 1.3 2007-09-03 13:52:01 francis Exp $

class AdminPublicBodyController < ApplicationController
    layout "admin"

    def index
        list
        render :action => 'list'
    end

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :destroy, :create, :update ],
                 :redirect_to => { :action => :list }

    def list
        @public_body_pages, @public_bodies = paginate :public_bodies, :per_page => 10
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
            redirect_to :action => 'list'
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
            redirect_to :action => 'show', :id => @public_body
        else
            render :action => 'edit'
        end
    end

    def destroy
        PublicBody.find(params[:id]).destroy
        redirect_to :action => 'list'
    end

    private

end
