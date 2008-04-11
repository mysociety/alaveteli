# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_user_controller.rb,v 1.3 2008-04-11 15:53:57 francis Exp $

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
            :conditions =>  @query.nil? ? nil : ["name ilike '%'||?||'%' or 
                             email ilike '%'||?||'%'", @query, @query]
    end

    def show
        # Don't use @user as that is any logged in user
        @admin_user = User.find(params[:id])
    end

    private

end
