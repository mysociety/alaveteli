# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_user_controller.rb,v 1.12 2009-07-22 08:23:18 francis Exp $

class AdminUserController < AdminController
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

    def list_banned
        @banned_users = User.paginate :order => "name", :page => params[:page], :per_page => 100,
            :conditions =>  ["ban_text <> ''"]
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
        @admin_user.ban_text = params[:admin_user][:ban_text]

        if @admin_user.valid?
            @admin_user.save!
            flash[:notice] = 'User successfully updated.'
            redirect_to user_admin_url(@admin_user)
        else
            render :action => 'edit'
        end
    end 

    def destroy_track
        track_thing = TrackThing.find(params[:track_id].to_i)
        track_thing.destroy
        flash[:notice] = 'Track destroyed'
        redirect_to user_admin_url(track_thing.tracking_user)
    end

    def login_as
        @admin_user = User.find(params[:id]) # check user does exist

        post_redirect = PostRedirect.new( :uri => frontpage_url(), :user_id => @admin_user.id)
        post_redirect.save!
        url = main_url(confirm_url(:email_token => post_redirect.email_token, :only_path => true))
            
        redirect_to url
    end

    private

end
