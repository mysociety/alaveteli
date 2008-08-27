# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_user_controller.rb,v 1.6 2008-08-27 00:39:03 francis Exp $

class AdminUserController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    def index
        list
        render :action => 'list'
    end

    def list
        @query = params[:query]
        @admin_users = User.paginate :order => "name", :page => params[:page], :per_page => 100,
            :conditions =>  @query.nil? ? nil : ["lower(name) like lower('%'||?||'%') or 
                             lower(email) like lower('%'||?||'%')", @query, @query]
    end

    def show
        # Don't use @user as that is any logged in user
        @admin_user = User.find(params[:id])
    end

    def edit
        @admin_user = User.find(params[:id])
    end

    def update
        @admin_user = User.find(params[:id])

        @admin_user.name = params[:admin_user][:name]
        @admin_user.email = params[:admin_user][:email]
        @admin_user.admin_level = params[:admin_user][:admin_level]

        if @admin_user.valid?
            @admin_user.save!
            flash[:notice] = 'User successfully updated.'
            redirect_to user_admin_url(@admin_user)
        else
            render :action => 'edit'
        end
    end 

 
    private

end
